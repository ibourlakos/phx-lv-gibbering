defmodule Gibbering.Engine.SceneServer do
  use GenServer

  import Ecto.Query
  alias Gibbering.{Repo, Campaign}
  alias Gibbering.Engine.{State, Rules, GameSession}

  @topic_prefix "game:"

  # --- Public API ---

  def start_link(game_id) do
    GenServer.start_link(__MODULE__, game_id, name: via(game_id))
  end

  def get_state(game_id), do: GenServer.call(via(game_id), :get_state)

  def select_entity(game_id, entity_id),
    do: GenServer.call(via(game_id), {:select_entity, entity_id})

  def move_entity(game_id, x, y),
    do: GenServer.call(via(game_id), {:move_entity, x, y})

  def attack_entity(game_id, target_id),
    do: GenServer.call(via(game_id), {:attack, target_id})

  def end_turn(game_id), do: GenServer.call(via(game_id), :end_turn)

  def transition_phase(game_id, new_phase),
    do: GenServer.call(via(game_id), {:transition_phase, new_phase, false})

  def force_transition_phase(game_id, new_phase),
    do: GenServer.call(via(game_id), {:transition_phase, new_phase, true})

  def topic(game_id), do: @topic_prefix <> to_string(game_id)

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
          :erlang.binary_to_term(binary, [:safe])

        nil ->
          campaign =
            Campaign
            |> Repo.get!(game_id)
            |> Repo.preload([:tiles, :entities])

          State.from_campaign(campaign)
      end

    {:ok, state}
  end

  @impl true
  def handle_call(:get_state, _from, state), do: {:reply, state, state}

  @impl true
  def handle_call({:select_entity, entity_id}, _from, state) do
    active = State.active_hero_id(state)

    new_state =
      if entity_id == active do
        moves = Rules.valid_moves(state, entity_id)
        %{state | selected_id: entity_id, valid_moves: moves}
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
        entity = state.entities[selected] |> Map.put(:x, x) |> Map.put(:y, y)

        targets =
          Rules.valid_targets(
            %{state | entities: Map.put(state.entities, selected, entity)},
            selected
          )

        %{
          state
          | entities: Map.put(state.entities, selected, entity),
            valid_moves: [],
            selected_id: selected
        }
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
        {_result, after_attack, _details} = Rules.attack(state, state.selected_id, target_id)
        State.advance_turn(after_attack)
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

  # --- Helpers ---

  defp put_targets(state, targets), do: Map.put(state, :valid_targets, targets)

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
    Phoenix.PubSub.broadcast(Gibbering.PubSub, topic(state.campaign_id), {:state_updated, state})
  end

  defp via(game_id), do: {:via, Registry, {Gibbering.GameRegistry, game_id}}
end
