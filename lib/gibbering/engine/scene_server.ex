defmodule Gibbering.Engine.SceneServer do
  @moduledoc """
  GenServer process that owns a running scene's `State` and dispatches player and DM
  actions. **Single-writer contract:** SceneServer is the sole emitter of `%EventBatch{}`
  messages on the game PubSub topic, and notification events (`%BroadcastSent{}`,
  `%WhisperDelivered{}`) on the notifications topic. No other process may broadcast to
  these topics. All commands targeting the scene must route through this module's public API.

  See the "Single-Writer Contract" section in docs/architecture.md for rationale.
  """

  use GenServer

  import Ecto.Query
  alias Gibbering.{Repo, Campaign, Entity, EventBus}
  alias Gibbering.Engine.{State, Rules, GameSession}
  alias Gibbering.Events.{EventBatch}
  alias Gibbering.Events.Notification.{BroadcastSent, WhisperDelivered}

  alias Gibbering.Events.Scene.{
    AttackResolved,
    ConditionApplied,
    ContainerOpened,
    DamageDealt,
    EntityMoved,
    HPAdjusted,
    ItemEquipped,
    ItemTaken,
    PhaseTransitioned,
    RollRequired,
    SessionEnded,
    SpellCast,
    TurnAdvanced
  }

  alias Gibbering.Engine.Inventory
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

  @doc """
  Resolves a melee attack from the selected entity against `target_id`.
  Pass `auto_roll: false` to pause for a player-submitted roll value instead of
  generating one server-side.
  """
  def attack_entity(game_id, target_id, opts \\ []),
    do: GenServer.call(via(game_id), {:attack, target_id, Keyword.get(opts, :auto_roll, true)})

  @doc """
  Resolves a spell cast from the selected entity using `spell_key` against `target_id`.
  Pass `auto_roll: false` to pause for a player-submitted roll value.
  """
  def cast_spell(game_id, spell_key, target_id, opts \\ []),
    do:
      GenServer.call(
        via(game_id),
        {:cast_spell, spell_key, target_id, Keyword.get(opts, :auto_roll, true)}
      )

  @doc """
  Submits a player-rolled value to resume the suspended action.
  `value` must be an integer in the valid range for the pending dice expression.
  """
  def submit_roll(game_id, entity_id, value),
    do: GenServer.call(via(game_id), {:submit_roll, entity_id, value})

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

  @doc "Ends the session: broadcasts a batch containing %SessionEnded{} to all connected LiveViews."
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

  @doc """
  Ends the initiative rolling phase and transitions to `:in_combat`.
  Returns `{:error, :pending_rolls}` if any player initiative rolls are still outstanding.
  """
  def end_initiative_rolling(game_id),
    do: GenServer.call(via(game_id), :end_initiative_rolling)

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

  @doc "Opens an adjacent loot container for the active hero. Returns `{:ok, state}` or `{:error, reason}`."
  def open_container(game_id, container_id),
    do: GenServer.call(via(game_id), {:open_container, container_id})

  @doc "Moves `quantity` units of `instance_id` from `container_id` to the active hero's inventory."
  def take_item(game_id, container_id, instance_id, quantity),
    do: GenServer.call(via(game_id), {:take_item, container_id, instance_id, quantity})

  @doc "Takes all items from `container_id` into the active hero's inventory."
  def take_all_items(game_id, container_id),
    do: GenServer.call(via(game_id), {:take_all_items, container_id})

  @doc "Equips the inventory item `instance_id` on the active hero."
  def equip_item(game_id, instance_id),
    do: GenServer.call(via(game_id), {:equip_item, instance_id})

  @doc "Closes the currently open container panel."
  def close_container(game_id),
    do: GenServer.call(via(game_id), :close_container)

  @doc "Clears actor_id, valid_moves, and valid_targets — display-only, no gameplay effect."
  def deselect_entity(game_id),
    do: GenServer.call(via(game_id), :deselect_entity)

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
            |> Repo.preload([:entities, active_map: :tiles])

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
  def handle_call({:attack, _, _}, _from, %{phase: :paused} = state),
    do: {:reply, state, state}

  @impl true
  def handle_call({:attack, _, _}, _from, %{awaiting_roll: true} = state),
    do: {:reply, state, state}

  @impl true
  def handle_call({:cast_spell, _, _, _}, _from, %{phase: :paused} = state),
    do: {:reply, state, state}

  @impl true
  def handle_call({:cast_spell, _, _, _}, _from, %{awaiting_roll: true} = state),
    do: {:reply, state, state}

  @impl true
  def handle_call(:end_turn, _from, %{phase: :paused} = state),
    do: {:reply, state, state}

  @impl true
  def handle_call(:end_turn, _from, %{awaiting_roll: true} = state),
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
    broadcast_batch(new_state, [], :reload_entities)
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:select_entity, entity_id}, _from, state) do
    active = State.active_hero_id(state)

    new_state =
      if entity_id == active do
        moves = Rules.valid_moves(state, entity_id)
        targets = Rules.valid_targets(state, entity_id)
        %{state | actor_id: entity_id, valid_moves: moves, valid_targets: targets}
      else
        state
      end

    persist(new_state)
    broadcast_batch(new_state, [], :select_entity)
    {:reply, new_state, new_state}
  end

  @impl true
  def handle_call({:move_entity, x, y}, _from, state) do
    selected = state.actor_id

    {new_state, events} =
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
        result = %{after_move | valid_moves: [], actor_id: selected} |> put_targets(targets)

        event = %EntityMoved{
          entity_id: selected,
          entity_name: entity.name,
          from: {entity.x, entity.y},
          to: {x, y},
          cost_ft: cost_ft
        }

        {result, [event]}
      else
        {state, []}
      end

    persist(new_state)
    broadcast_batch(new_state, events, :move_entity)
    {:reply, new_state, new_state}
  end

  @impl true
  def handle_call({:attack, target_id, auto_roll}, _from, state) do
    {new_state, events} =
      if state.actor_id do
        attacker_id = state.actor_id
        attacker = state.entities[attacker_id]
        target = state.entities[target_id]

        if not auto_roll do
          paused = %{
            state
            | awaiting_roll: true,
              pending_roll: {:attack, target_id}
          }

          Process.send_after(self(), {:auto_roll_timeout, attacker_id}, 60_000)

          roll_event = %RollRequired{
            entity_id: attacker_id,
            roll_type: :attack,
            dice_expression: "1d20",
            context_label: "Attack vs #{target.name}"
          }

          {paused, [roll_event]}
        else
          do_attack(state, attacker_id, attacker, target_id, target, [])
        end
      else
        {state, []}
      end

    persist(new_state)
    broadcast_batch(new_state, events, :attack)
    {:reply, new_state, new_state}
  end

  @impl true
  def handle_call({:cast_spell, spell_key, target_id, auto_roll}, _from, state) do
    {new_state, events} =
      if state.actor_id do
        caster_id = state.actor_id
        caster = state.entities[caster_id]
        target = state.entities[target_id]

        spell = Gibbering.Data.Spells.get(spell_key)
        needs_roll = spell && spell.effect.attack_type in [:melee_attack, :ranged_attack]

        if not auto_roll and needs_roll do
          paused = %{
            state
            | awaiting_roll: true,
              pending_roll: {:cast_spell, spell_key, target_id}
          }

          Process.send_after(self(), {:auto_roll_timeout, caster_id}, 60_000)

          spell_name = (spell && spell.name) || spell_key

          roll_event = %RollRequired{
            entity_id: caster_id,
            roll_type: :attack,
            dice_expression: "1d20",
            context_label: "#{spell_name} vs #{target.name}"
          }

          {paused, [roll_event]}
        else
          do_cast_spell(state, caster_id, caster, spell_key, target_id, target, [])
        end
      else
        {state, []}
      end

    persist(new_state)
    broadcast_batch(new_state, events, :cast_spell)
    {:reply, new_state, new_state}
  end

  @impl true
  def handle_call(:end_turn, _from, state) do
    new_state = State.advance_turn(state)
    persist(new_state)
    broadcast_batch(new_state, [build_turn_advanced(state, new_state)], :end_turn)
    {:reply, new_state, new_state}
  end

  @impl true
  def handle_call(:resume_session, _from, %{phase: :paused, previous_phase: prev} = state)
      when not is_nil(prev) do
    case State.transition_phase(state, prev) do
      {:ok, new_state} ->
        event = %PhaseTransitioned{from_phase: state.phase, to_phase: new_state.phase}
        persist(new_state)
        broadcast_batch(new_state, [event], :resume_session)
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
    event = %SessionEnded{campaign_id: state.campaign_id}
    persist(state)
    broadcast_batch(state, [event], :end_session)
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:set_initiative, entity_id, value}, _from, state) do
    new_state = State.set_initiative(state, entity_id, value)
    persist(new_state)
    broadcast_batch(new_state, [], :set_initiative)
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:add_to_turn_order, entity_id}, _from, state) do
    new_state = State.add_to_turn_order(state, entity_id)
    persist(new_state)
    broadcast_batch(new_state, [], :add_to_turn_order)
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:remove_from_turn_order, entity_id}, _from, state) do
    new_state = State.remove_from_turn_order(state, entity_id)
    persist(new_state)
    broadcast_batch(new_state, [], :remove_from_turn_order)
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:reorder_turn_order, ordered_ids}, _from, state) do
    new_state = State.reorder_turn_order(state, ordered_ids)
    persist(new_state)
    broadcast_batch(new_state, [], :reorder_turn_order)
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:force_end_turn, _from, state) do
    new_state = State.advance_turn(state)
    persist(new_state)
    broadcast_batch(new_state, [build_turn_advanced(state, new_state)], :force_end_turn)
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:transition_phase, :initiative_rolling, false}, _from, state) do
    case State.transition_phase(state, :initiative_rolling) do
      {:ok, transitioned} ->
        hero_ids =
          state.entities
          |> Enum.filter(fn {_, e} -> e.type == "hero" end)
          |> Enum.map(fn {id, _} -> id end)

        manual_hero_ids = manual_roll_heroes(state.campaign_id, hero_ids)

        {new_state, roll_events} =
          Enum.reduce(manual_hero_ids, {transitioned, []}, fn entity_id,
                                                              {acc_state, acc_events} ->
            entity = acc_state.entities[entity_id]
            pending = MapSet.put(acc_state.pending_initiative_rolls, entity_id)
            Process.send_after(self(), {:initiative_timeout, entity_id}, 60_000)

            event = %RollRequired{
              entity_id: entity_id,
              roll_type: :initiative,
              dice_expression: "1d20",
              context_label: "Initiative — #{entity.name}"
            }

            {%{acc_state | pending_initiative_rolls: pending}, [event | acc_events]}
          end)

        phase_event = %PhaseTransitioned{from_phase: state.phase, to_phase: :initiative_rolling}
        events = [phase_event] ++ Enum.reverse(roll_events)
        persist(new_state)
        broadcast_batch(new_state, events, :transition_phase)
        {:reply, :ok, new_state}

      {:error, _reason} = err ->
        {:reply, err, state}
    end
  end

  @impl true
  def handle_call(:end_initiative_rolling, _from, %{phase: :initiative_rolling} = state) do
    if MapSet.size(state.pending_initiative_rolls) > 0 do
      {:reply, {:error, :pending_rolls}, state}
    else
      case State.transition_phase(state, :in_combat) do
        {:ok, new_state} ->
          event = %PhaseTransitioned{from_phase: :initiative_rolling, to_phase: :in_combat}
          persist(new_state)
          broadcast_batch(new_state, [event], :end_initiative_rolling)
          {:reply, :ok, new_state}

        {:error, _} = err ->
          {:reply, err, state}
      end
    end
  end

  @impl true
  def handle_call(:end_initiative_rolling, _from, state),
    do: {:reply, {:error, :wrong_phase}, state}

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
        event = %PhaseTransitioned{from_phase: state.phase, to_phase: new_state.phase}
        persist(new_state)
        broadcast_batch(new_state, [event], :transition_phase)
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
    entity = state.entities[entity_id]

    event = %ConditionApplied{
      entity_id: entity_id,
      entity_name: entity && entity.name,
      condition_id: condition_id
    }

    persist(new_state)
    broadcast_batch(new_state, [event], :dm_apply_condition)
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:dm_adjust_hp, entity_id, delta}, _from, state) do
    after_hp = State.adjust_hp(state, entity_id, delta)
    entry = "HP adjusted: entity #{entity_id} by #{delta}"
    after_hp = State.add_log_entry(after_hp, entry)
    entity = state.entities[entity_id]
    old_hp = if entity, do: entity.hp, else: nil

    new_hp =
      if entity, do: after_hp.entities[entity_id] && after_hp.entities[entity_id].hp, else: nil

    hp_event = %HPAdjusted{
      entity_id: entity_id,
      entity_name: entity && entity.name,
      old_hp: old_hp,
      new_hp: new_hp,
      reason: :dm_adjust
    }

    {new_state, outcome_events} = maybe_trigger_outcome(after_hp)

    persist(new_state)
    broadcast_batch(new_state, [hp_event] ++ outcome_events, :dm_adjust_hp)
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:dm_toggle_visibility, entity_id}, _from, state) do
    new_state = State.toggle_visibility(state, entity_id)
    persist(new_state)
    broadcast_batch(new_state, [], :dm_toggle_visibility)
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:open_container, container_id}, _from, state) do
    actor_id = state.actor_id || State.active_hero_id(state)
    actor = state.entities[actor_id]
    container = state.entities[container_id]

    case Inventory.can_open_container?(actor, container) do
      :ok ->
        new_state = %{state | open_container_id: container_id}
        persist(new_state)

        event = %ContainerOpened{actor_id: actor_id, container_id: container_id}
        broadcast_batch(new_state, [event], :open_container)
        {:reply, {:ok, new_state}, new_state}

      {:error, _} = err ->
        {:reply, err, state}
    end
  end

  @impl true
  def handle_call({:take_item, container_id, instance_id, quantity}, _from, state) do
    actor_id = state.actor_id || State.active_hero_id(state)
    actor = state.entities[actor_id]
    container = state.entities[container_id]

    case Inventory.take_item(actor, container, instance_id, quantity) do
      {:error, _} = err ->
        {:reply, err, state}

      {:ok, new_actor, new_container} ->
        new_entities =
          state.entities
          |> Map.put(actor_id, new_actor)
          |> Map.put(container_id, new_container)

        open_id = if new_container.stats["items"] == [], do: nil, else: state.open_container_id

        new_state = %{state | entities: new_entities, open_container_id: open_id}
        persist(new_state)

        event = %ItemTaken{
          actor_id: actor_id,
          container_id: container_id,
          instance_id: instance_id,
          item_key: List.first(new_actor.stats["inventory"] || [])["item_key"],
          quantity: quantity
        }

        broadcast_batch(new_state, [event], :take_item)
        {:reply, {:ok, new_state}, new_state}
    end
  end

  @impl true
  def handle_call({:take_all_items, container_id}, _from, state) do
    actor_id = state.actor_id || State.active_hero_id(state)
    actor = state.entities[actor_id]
    container = state.entities[container_id]
    items = get_in(container, [:stats, "items"]) || []

    {new_actor, events} =
      Enum.reduce(items, {actor, []}, fn inst, {acc_actor, acc_events} ->
        case Inventory.take_item(
               acc_actor,
               %{container | stats: Map.put(container.stats, "items", [inst])},
               inst["instance_id"],
               inst["quantity"]
             ) do
          {:ok, updated_actor, _} ->
            event = %ItemTaken{
              actor_id: actor_id,
              container_id: container_id,
              instance_id: inst["instance_id"],
              item_key: inst["item_key"],
              quantity: inst["quantity"]
            }

            {updated_actor, acc_events ++ [event]}

          {:error, _} ->
            {acc_actor, acc_events}
        end
      end)

    empty_container = put_in(container, [:stats, "items"], [])

    new_entities =
      state.entities
      |> Map.put(actor_id, new_actor)
      |> Map.put(container_id, empty_container)

    new_state = %{state | entities: new_entities, open_container_id: nil}
    persist(new_state)
    broadcast_batch(new_state, events, :take_all_items)
    {:reply, {:ok, new_state}, new_state}
  end

  @impl true
  def handle_call({:equip_item, instance_id}, _from, state) do
    actor_id = state.actor_id || State.active_hero_id(state)
    actor = state.entities[actor_id]

    case Inventory.equip_item(actor, instance_id) do
      {:error, _} = err ->
        {:reply, err, state}

      {:ok, new_actor} ->
        inventory = get_in(actor, [:stats, "inventory"]) || []
        item_key = (Enum.find(inventory, &(&1["instance_id"] == instance_id)) || %{})["item_key"]
        item = Gibbering.Data.Items.get(item_key)
        slot = if item && item.item_type == :weapon, do: "equipped_weapon", else: "equipped_armor"

        new_entities = Map.put(state.entities, actor_id, new_actor)
        new_state = %{state | entities: new_entities}
        persist(new_state)

        event = %ItemEquipped{
          actor_id: actor_id,
          instance_id: instance_id,
          item_key: item_key,
          slot: slot
        }

        broadcast_batch(new_state, [event], :equip_item)
        {:reply, {:ok, new_state}, new_state}
    end
  end

  @impl true
  def handle_call(:close_container, _from, state) do
    new_state = %{state | open_container_id: nil}
    persist(new_state)
    broadcast_batch(new_state, [], :close_container)
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:deselect_entity, _from, state) do
    new_state = %{state | actor_id: nil, valid_moves: [], valid_targets: []}
    persist(new_state)
    broadcast_batch(new_state, [], :deselect_entity)
    {:reply, new_state, new_state}
  end

  @impl true
  def handle_call({:submit_roll, entity_id, value}, _from, %{awaiting_roll: true} = state) do
    {new_state, events} =
      case state.pending_roll do
        {:attack, target_id} ->
          attacker = state.entities[entity_id]
          target = state.entities[target_id]

          cleared = %{state | awaiting_roll: false, pending_roll: nil}

          if attacker && target do
            do_attack(cleared, entity_id, attacker, target_id, target, roll: value)
          else
            {cleared, []}
          end

        {:cast_spell, spell_key, target_id} ->
          caster = state.entities[entity_id]
          target = state.entities[target_id]

          cleared = %{state | awaiting_roll: false, pending_roll: nil}

          if caster && target do
            do_cast_spell(cleared, entity_id, caster, spell_key, target_id, target, roll: value)
          else
            {cleared, []}
          end

        _ ->
          {%{state | awaiting_roll: false, pending_roll: nil}, []}
      end

    persist(new_state)
    broadcast_batch(new_state, events, :submit_roll)
    {:reply, new_state, new_state}
  end

  @impl true
  def handle_call({:submit_roll, entity_id, value}, _from, state) do
    cond do
      MapSet.member?(state.pending_initiative_rolls, entity_id) ->
        new_state =
          state
          |> State.set_initiative(entity_id, value)
          |> then(fn s ->
            %{s | pending_initiative_rolls: MapSet.delete(s.pending_initiative_rolls, entity_id)}
          end)

        persist(new_state)
        broadcast_batch(new_state, [], :submit_initiative_roll)
        {:reply, new_state, new_state}

      true ->
        {:reply, state, state}
    end
  end

  @impl true
  def handle_info({:auto_roll_timeout, entity_id}, %{awaiting_roll: true} = state) do
    {new_state, events} =
      case state.pending_roll do
        {:attack, target_id} ->
          attacker = state.entities[entity_id]
          target = state.entities[target_id]
          cleared = %{state | awaiting_roll: false, pending_roll: nil}

          if attacker && target do
            do_attack(cleared, entity_id, attacker, target_id, target, [])
          else
            {cleared, []}
          end

        {:cast_spell, spell_key, target_id} ->
          caster = state.entities[entity_id]
          target = state.entities[target_id]
          cleared = %{state | awaiting_roll: false, pending_roll: nil}

          if caster && target do
            do_cast_spell(cleared, entity_id, caster, spell_key, target_id, target, [])
          else
            {cleared, []}
          end

        _ ->
          {%{state | awaiting_roll: false, pending_roll: nil}, []}
      end

    persist(new_state)
    broadcast_batch(new_state, events, :auto_roll_timeout)
    {:noreply, new_state}
  end

  @impl true
  def handle_info({:auto_roll_timeout, _entity_id}, state), do: {:noreply, state}

  @impl true
  def handle_info({:initiative_timeout, entity_id}, state) do
    if MapSet.member?(state.pending_initiative_rolls, entity_id) do
      roll = Enum.random(1..20)

      new_state =
        state
        |> State.set_initiative(entity_id, roll)
        |> then(fn s ->
          %{s | pending_initiative_rolls: MapSet.delete(s.pending_initiative_rolls, entity_id)}
        end)

      persist(new_state)
      broadcast_batch(new_state, [], :initiative_timeout)
      {:noreply, new_state}
    else
      {:noreply, state}
    end
  end

  # --- Helpers ---

  defp put_targets(state, targets), do: %{state | valid_targets: targets}

  # Returns hero entity IDs that need a RollRequired event for initiative.
  # Because Entity rows are not directly linked to CampaignCharacter records,
  # we emit prompts for all heroes and let each player's LiveView decide whether
  # to show the prompt (auto_roll: false) or auto-submit immediately (auto_roll: true).
  defp manual_roll_heroes(_campaign_id, hero_ids), do: hero_ids

  defp do_attack(state, attacker_id, attacker, target_id, target, opts) do
    case Rules.attack(state, attacker_id, target_id, opts) do
      {:error, _reason} ->
        {state, []}

      {_result, after_attack, details} ->
        advanced = State.advance_turn(after_attack)

        attack_event = %AttackResolved{
          attacker_id: attacker_id,
          attacker_name: attacker.name,
          target_id: target_id,
          target_name: target.name,
          roll: details.roll,
          hit?: details.hit
        }

        damage_events =
          if details.hit do
            new_hp =
              case Map.get(after_attack.entities, target_id) do
                nil -> 0
                e -> e.hp
              end

            [
              %DamageDealt{
                target_id: target_id,
                target_name: target.name,
                amount: details.damage,
                damage_type: nil,
                new_hp: new_hp
              }
            ]
          else
            []
          end

        {outcome_state, outcome_events} = maybe_trigger_outcome(advanced)

        {outcome_state,
         [attack_event] ++
           damage_events ++
           [build_turn_advanced(state, advanced)] ++
           outcome_events}
    end
  end

  defp do_cast_spell(state, caster_id, caster, spell_key, target_id, target, opts) do
    case Rules.cast_spell(state, caster_id, spell_key, target_id, opts) do
      {:error, _reason} ->
        {state, []}

      {result, after_cast, details} ->
        advanced = State.advance_turn(after_cast)

        spell_event = %SpellCast{
          caster_id: caster_id,
          caster_name: caster.name,
          spell_key: spell_key,
          target_id: target_id,
          target_name: target.name,
          outcome: result
        }

        damage_events =
          if details[:hit] && details[:damage] do
            new_hp =
              case Map.get(after_cast.entities, target_id) do
                nil -> 0
                e -> e.hp
              end

            [
              %DamageDealt{
                target_id: target_id,
                target_name: target.name,
                amount: details[:damage],
                damage_type: nil,
                new_hp: new_hp
              }
            ]
          else
            []
          end

        {outcome_state, outcome_events} = maybe_trigger_outcome(advanced)

        {outcome_state,
         [spell_event] ++
           damage_events ++
           [build_turn_advanced(state, advanced)] ++
           outcome_events}
    end
  end

  defp maybe_trigger_outcome(%{phase: :in_combat} = state) do
    case State.check_combat_outcome(state) do
      nil ->
        {state, []}

      outcome ->
        {:ok, new_state} = State.transition_phase(state, outcome)
        event = %PhaseTransitioned{from_phase: :in_combat, to_phase: outcome}
        {new_state, [event]}
    end
  end

  defp maybe_trigger_outcome(state), do: {state, []}

  defp chebyshev(x1, y1, x2, y2), do: max(abs(x1 - x2), abs(y1 - y2))

  defp broadcast_batch(state, raw_events, command) do
    now = DateTime.utc_now()
    corr_id = Ecto.UUID.generate()
    event_ids = Enum.map(raw_events, fn _ -> Ecto.UUID.generate() end)

    events =
      raw_events
      |> Enum.with_index()
      |> Enum.map(fn {event, i} ->
        %{
          event
          | event_id: Enum.at(event_ids, i),
            occurred_at: now,
            correlation_id: corr_id,
            causation_id: if(i == 0, do: corr_id, else: Enum.at(event_ids, i - 1)),
            sequence_number: i
        }
      end)

    batch = %EventBatch{
      batch_id: Ecto.UUID.generate(),
      command: command,
      correlation_id: corr_id,
      occurred_at: now,
      events: events,
      state_snapshot: state
    }

    EventBus.broadcast(topic(state.campaign_id), batch)
  end

  defp build_turn_advanced(before_state, after_state) do
    from_id = State.active_hero_id(before_state)
    to_id = State.active_hero_id(after_state)

    %TurnAdvanced{
      from_entity_id: from_id,
      from_entity_name: from_id && before_state.entities[from_id].name,
      to_entity_id: to_id,
      to_entity_name: to_id && (Map.get(after_state.entities, to_id) || %{name: nil}).name,
      round_number: nil
    }
  end

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

  defp via(game_id), do: {:via, Registry, {Gibbering.GameRegistry, game_id}}
end
