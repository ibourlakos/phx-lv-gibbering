defmodule Gibbering.Engine.SceneServer do
  @moduledoc """
  GenServer process that owns a running scene's `State` and dispatches player and DM
  actions. **Single-writer contract:** SceneServer is the sole emitter of scene-domain
  events (`{:state_updated, state}`, `:session_ended`) on the game PubSub topic, and
  notification events (`%BroadcastSent{}`, `%WhisperDelivered{}`) on the notifications
  topic. No other process may broadcast to these topics with scene or notification
  messages. All commands targeting the scene must route through this module's public API.

  See the "Single-Writer Contract" section in docs/architecture.md for rationale.
  """

  use GenServer

  import Ecto.Query
  alias Gibbering.{Repo, Campaign, Entity, EventBus}
  alias Gibbering.Engine.{State, Rules, GameSession}
  alias Gibbering.Events.Notification.{BroadcastSent, WhisperDelivered}
  alias Gibbering.Rulesets.DnD5e.Stats

  @topic_prefix "game:"
  @notifications_prefix "notifications:"

  # --- Public API ---

  @doc false
  def start_link(game_id) do
    GenServer.start_link(__MODULE__, game_id, name: via(game_id))
  end

  @doc "Returns the current `%State{}` for the given game."
  def get_state(game_id), do: GenServer.call(via(game_id), :get_state)

  @doc "Selects `entity_id` as the active entity, computing valid moves."
  def select_entity(game_id, entity_id),
    do: GenServer.call(via(game_id), {:select_entity, entity_id})

  @doc "Moves the selected entity to `{x, y}` if the tile is reachable this turn."
  def move_entity(game_id, x, y),
    do: GenServer.call(via(game_id), {:move_entity, x, y})

  @doc "Resolves a melee attack from the selected entity against `target_id`."
  def attack_entity(game_id, target_id),
    do: GenServer.call(via(game_id), {:attack, target_id})

  @doc "Resolves a spell cast from the selected entity using `spell_key` against `target_id`."
  def cast_spell(game_id, spell_key, target_id),
    do: GenServer.call(via(game_id), {:cast_spell, spell_key, target_id})

  @doc "Ends the current hero's turn and advances to the next in the turn order."
  def end_turn(game_id), do: GenServer.call(via(game_id), :end_turn)

  @doc "Requests a validated scene phase transition."
  def transition_phase(game_id, new_phase),
    do: GenServer.call(via(game_id), {:transition_phase, new_phase, false})

  @doc "Forces a scene phase transition without validation — DM override only."
  def force_transition_phase(game_id, new_phase),
    do: GenServer.call(via(game_id), {:transition_phase, new_phase, true})

  @doc "Transitions the session from lobby to active exploration state."
  def start_session(game_id), do: transition_phase(game_id, :exploration)

  @doc "Pauses the session, blocking player actions until resumed."
  def pause_session(game_id), do: transition_phase(game_id, :paused)

  @doc "Resumes a paused session, restoring the phase that was active before pausing."
  def resume_session(game_id), do: GenServer.call(via(game_id), :resume_session)

  @doc "Ends the session: broadcasts :session_ended to all connected LiveViews."
  def end_session(game_id), do: GenServer.call(via(game_id), :end_session)

  @doc "Sets the initiative value for `entity_id` and re-sorts the turn order."
  def set_initiative(game_id, entity_id, value),
    do: GenServer.call(via(game_id), {:set_initiative, entity_id, value})

  @doc "Adds `entity_id` to the turn order. No-op if already present."
  def add_to_turn_order(game_id, entity_id),
    do: GenServer.call(via(game_id), {:add_to_turn_order, entity_id})

  @doc "Removes `entity_id` from the turn order."
  def remove_from_turn_order(game_id, entity_id),
    do: GenServer.call(via(game_id), {:remove_from_turn_order, entity_id})

  @doc "Replaces the turn order with `ordered_ids` (DM reorder)."
  def reorder_turn_order(game_id, ordered_ids),
    do: GenServer.call(via(game_id), {:reorder_turn_order, ordered_ids})

  @doc "DM-driven turn advance — bypasses the paused guard."
  def force_end_turn(game_id), do: GenServer.call(via(game_id), :force_end_turn)

  @doc "Broadcasts a narrative text to all players in this session."
  def dm_broadcast(game_id, text), do: GenServer.call(via(game_id), {:dm_broadcast, text})

  @doc "Delivers a private whisper to a single player's per-user PubSub topic."
  def dm_whisper(game_id, user_id, text),
    do: GenServer.call(via(game_id), {:dm_whisper, user_id, text})

  @doc "Applies a condition to `entity_id` via the DM panel."
  def dm_apply_condition(game_id, entity_id, condition_id),
    do: GenServer.call(via(game_id), {:dm_apply_condition, entity_id, condition_id})

  @doc "Adjusts HP on `entity_id` by `delta` (positive = heal, negative = damage)."
  def dm_adjust_hp(game_id, entity_id, delta),
    do: GenServer.call(via(game_id), {:dm_adjust_hp, entity_id, delta})

  @doc "Toggles `entity_id` in the DM-hidden set."
  def dm_toggle_visibility(game_id, entity_id),
    do: GenServer.call(via(game_id), {:dm_toggle_visibility, entity_id})

  @doc "Returns true if a SceneServer for `game_id` is currently registered."
  def running?(game_id) do
    Registry.lookup(Gibbering.GameRegistry, game_id) != []
  end

  @doc """
  Re-fetches all entities for the campaign from DB and merges them into the
  running state, preserving runtime fields (position, action economy, resources,
  conditions). Broadcasts the updated state. No-op if the server is not running.
  """
  def reload_entities(game_id), do: GenServer.call(via(game_id), :reload_entities)

  @doc "Returns the PubSub topic string for broadcasting scene updates to subscribers."
  def topic(game_id), do: @topic_prefix <> to_string(game_id)

  @doc "Returns the PubSub topic string for broadcasting notification events to subscribers."
  def notifications_topic(game_id), do: @notifications_prefix <> to_string(game_id)

  @doc """
  Ensures a SceneServer for `game_id` is running under the SceneSupervisor.
  If one is already registered, returns `:ok` immediately.
  Returns `:ok` or `{:error, reason}`.
  """
  def ensure_started(game_id) do
    case Registry.lookup(Gibbering.GameRegistry, game_id) do
      [_] ->
        :ok

      [] ->
        case DynamicSupervisor.start_child(Gibbering.SceneSupervisor, {__MODULE__, game_id}) do
          {:ok, _pid} -> :ok
          {:error, {:already_started, _pid}} -> :ok
          {:error, reason} -> {:error, reason}
        end
    end
  end

  # --- GenServer callbacks ---

  @impl true
  def init(game_id) do
    state =
      case Repo.one(from s in GameSession, where: s.game_id == ^game_id) do
        %GameSession{state: binary} ->
          loaded = :erlang.binary_to_term(binary, [:safe])
          struct(State, Map.from_struct(loaded))

        nil ->
          campaign =
            Campaign
            |> Repo.get!(game_id)
            |> Repo.preload([:tiles, :entities])

          State.from_campaign(campaign)
      end

    {:ok, state}
  end

  # Player actions are blocked while the session is paused.
  @impl true
  def handle_call({:select_entity, _}, _from, %{phase: :paused} = state),
    do: {:reply, state, state}

  @impl true
  def handle_call({:move_entity, _, _}, _from, %{phase: :paused} = state),
    do: {:reply, state, state}

  @impl true
  def handle_call({:attack, _}, _from, %{phase: :paused} = state),
    do: {:reply, state, state}

  @impl true
  def handle_call({:cast_spell, _, _}, _from, %{phase: :paused} = state),
    do: {:reply, state, state}

  @impl true
  def handle_call(:end_turn, _from, %{phase: :paused} = state),
    do: {:reply, state, state}

  @impl true
  def handle_call(:get_state, _from, state), do: {:reply, state, state}

  @impl true
  def handle_call(:reload_entities, _from, state) do
    db_entities =
      Entity
      |> where(campaign_id: ^state.campaign_id)
      |> Repo.all()

    ruleset = state.ruleset

    new_entities =
      Map.new(db_entities, fn e ->
        base = %{
          name: e.name,
          type: e.type,
          sprite: e.sprite,
          race: e.race || "human",
          class: e.class || "fighter",
          hp: e.hp,
          max_hp: e.max_hp,
          level: e.level,
          temp_hp: e.temp_hp,
          tags: e.tags,
          stats: e.stats,
          speed: (e.stats || %{})["speed"] || 30
        }

        merged =
          case Map.get(state.entities, e.id) do
            nil ->
              base
              |> Map.put(:x, e.x)
              |> Map.put(:y, e.y)
              |> Map.put(:action_economy, ruleset.initial_action_economy(base))
              |> Map.put(:resources, ruleset.initial_resources(base))
              |> Map.put(:conditions, [])
              |> Stats.hydrate_entity()

            existing ->
              base
              |> Map.put(:x, existing.x)
              |> Map.put(:y, existing.y)
              |> Map.put(:action_economy, existing.action_economy)
              |> Map.put(:resources, existing.resources)
              |> Map.put(:conditions, existing.conditions)
              |> Stats.hydrate_entity()
          end

        {e.id, merged}
      end)

    hero_ids =
      db_entities
      |> Enum.filter(&(&1.type == "hero"))
      |> Enum.map(& &1.id)

    # Keep active_index in bounds after any hero list changes.
    new_active_index = min(state.active_index, max(length(hero_ids) - 1, 0))

    new_state = %{
      state
      | entities: new_entities,
        turn_order: hero_ids,
        active_index: new_active_index
    }

    persist(new_state)
    broadcast(new_state)
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:select_entity, entity_id}, _from, state) do
    active = State.active_hero_id(state)

    new_state =
      if entity_id == active do
        moves = Rules.valid_moves(state, entity_id)
        targets = Rules.valid_targets(state, entity_id)
        %{state | selected_id: entity_id, valid_moves: moves, valid_targets: targets}
      else
        state
      end

    persist(new_state)
    broadcast(new_state)
    {:reply, new_state, new_state}
  end

  @impl true
  def handle_call({:move_entity, x, y}, _from, state) do
    selected = state.selected_id

    new_state =
      if selected && {x, y} in state.valid_moves do
        entity = state.entities[selected]
        cost_ft = chebyshev(entity.x, entity.y, x, y) * 5

        moved_state =
          state
          |> put_in([Access.key(:entities), selected, :x], x)
          |> put_in([Access.key(:entities), selected, :y], y)

        after_move =
          case State.consume_movement(moved_state, selected, cost_ft) do
            {:ok, s} -> s
            {:error, _} -> moved_state
          end

        targets = Rules.valid_targets(after_move, selected)

        %{after_move | valid_moves: [], selected_id: selected}
        |> put_targets(targets)
      else
        state
      end

    persist(new_state)
    broadcast(new_state)
    {:reply, new_state, new_state}
  end

  @impl true
  def handle_call({:attack, target_id}, _from, state) do
    new_state =
      if state.selected_id do
        case Rules.attack(state, state.selected_id, target_id) do
          {:error, _reason} -> state
          {_result, after_attack, _details} -> State.advance_turn(after_attack)
        end
      else
        state
      end

    persist(new_state)
    broadcast(new_state)
    {:reply, new_state, new_state}
  end

  @impl true
  def handle_call({:cast_spell, spell_key, target_id}, _from, state) do
    new_state =
      if state.selected_id do
        case Rules.cast_spell(state, state.selected_id, spell_key, target_id) do
          {:error, _reason} -> state
          {_result, after_cast, _details} -> State.advance_turn(after_cast)
        end
      else
        state
      end

    persist(new_state)
    broadcast(new_state)
    {:reply, new_state, new_state}
  end

  @impl true
  def handle_call(:end_turn, _from, state) do
    new_state = State.advance_turn(state)
    persist(new_state)
    broadcast(new_state)
    {:reply, new_state, new_state}
  end

  @impl true
  def handle_call(:resume_session, _from, %{phase: :paused, previous_phase: prev} = state)
      when not is_nil(prev) do
    case State.transition_phase(state, prev) do
      {:ok, new_state} ->
        persist(new_state)
        broadcast(new_state)
        {:reply, :ok, new_state}

      {:error, _} = err ->
        {:reply, err, state}
    end
  end

  @impl true
  def handle_call(:resume_session, _from, state),
    do: {:reply, {:error, "session is not paused"}, state}

  @impl true
  def handle_call(:end_session, _from, state) do
    persist(state)
    EventBus.broadcast(topic(state.campaign_id), :session_ended)
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:set_initiative, entity_id, value}, _from, state) do
    new_state = State.set_initiative(state, entity_id, value)
    persist(new_state)
    broadcast(new_state)
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:add_to_turn_order, entity_id}, _from, state) do
    new_state = State.add_to_turn_order(state, entity_id)
    persist(new_state)
    broadcast(new_state)
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:remove_from_turn_order, entity_id}, _from, state) do
    new_state = State.remove_from_turn_order(state, entity_id)
    persist(new_state)
    broadcast(new_state)
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:reorder_turn_order, ordered_ids}, _from, state) do
    new_state = State.reorder_turn_order(state, ordered_ids)
    persist(new_state)
    broadcast(new_state)
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:force_end_turn, _from, state) do
    new_state = State.advance_turn(state)
    persist(new_state)
    broadcast(new_state)
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:transition_phase, new_phase, force}, _from, state) do
    result =
      if force do
        State.force_transition_phase(state, new_phase)
      else
        State.transition_phase(state, new_phase)
      end

    case result do
      {:ok, new_state} ->
        persist(new_state)
        broadcast(new_state)
        {:reply, :ok, new_state}

      {:error, _reason} = err ->
        {:reply, err, state}
    end
  end

  @impl true
  def handle_call({:dm_broadcast, text}, _from, state) do
    entry = "Broadcast: #{text}"
    new_state = State.add_log_entry(state, entry)
    persist(new_state)

    event = %BroadcastSent{
      event_id: Ecto.UUID.generate(),
      campaign_id: state.campaign_id,
      text: text,
      sent_at: DateTime.utc_now()
    }

    EventBus.broadcast(notifications_topic(state.campaign_id), event)
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:dm_whisper, user_id, text}, _from, state) do
    event = %WhisperDelivered{
      event_id: Ecto.UUID.generate(),
      campaign_id: state.campaign_id,
      target_player_id: user_id,
      text: text,
      sent_at: DateTime.utc_now()
    }

    EventBus.broadcast(notifications_topic(state.campaign_id), event)
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:dm_apply_condition, entity_id, condition_id}, _from, state) do
    {:ok, new_state} = State.apply_condition(state, entity_id, condition_id)
    entry = "Condition applied: #{condition_id} → entity #{entity_id}"
    new_state = State.add_log_entry(new_state, entry)
    persist(new_state)
    broadcast(new_state)
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:dm_adjust_hp, entity_id, delta}, _from, state) do
    new_state = State.adjust_hp(state, entity_id, delta)
    entry = "HP adjusted: entity #{entity_id} by #{delta}"
    new_state = State.add_log_entry(new_state, entry)
    persist(new_state)
    broadcast(new_state)
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:dm_toggle_visibility, entity_id}, _from, state) do
    new_state = State.toggle_visibility(state, entity_id)
    persist(new_state)
    broadcast(new_state)
    {:reply, :ok, new_state}
  end

  # --- Helpers ---

  defp put_targets(state, targets), do: %{state | valid_targets: targets}

  defp chebyshev(x1, y1, x2, y2), do: max(abs(x1 - x2), abs(y1 - y2))

  defp persist(state) do
    binary = :erlang.term_to_binary(state, [:compressed])
    game_id = state.campaign_id

    case Repo.one(from s in GameSession, where: s.game_id == ^game_id) do
      nil ->
        %GameSession{}
        |> GameSession.changeset(%{game_id: game_id, state: binary})
        |> Repo.insert!(on_conflict: :nothing)

      existing ->
        existing
        |> GameSession.changeset(%{state: binary})
        |> Repo.update!()
    end

    state
  end

  defp broadcast(state) do
    EventBus.broadcast(topic(state.campaign_id), {:state_updated, state})
  end

  defp via(game_id), do: {:via, Registry, {Gibbering.GameRegistry, game_id}}
end
