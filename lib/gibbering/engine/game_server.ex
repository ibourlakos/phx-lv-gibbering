defmodule Gibbering.Engine.GameServer do
  use GenServer

  alias Gibbering.{Repo, Campaign}
  alias Gibbering.Engine.{State, Rules}

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

  def topic(game_id), do: @topic_prefix <> to_string(game_id)

  # --- GenServer callbacks ---

  @impl true
  def init(game_id) do
    campaign =
      Campaign
      |> Repo.get!(game_id)
      |> Repo.preload([:tiles, :entities])

    {:ok, State.from_campaign(campaign)}
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

    broadcast(new_state)
    {:reply, new_state, new_state}
  end

  @impl true
  def handle_call({:move_entity, x, y}, _from, state) do
    selected = state.selected_id

    new_state =
      if selected && {x, y} in state.valid_moves do
        entity = Map.put(state.entities[selected], :x, x) |> Map.put(:y, y)

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
        |> then(fn s -> %{s | valid_moves: [], selected_id: selected} end)
        |> put_targets(targets)
      else
        state
      end

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

    broadcast(new_state)
    {:reply, new_state, new_state}
  end

  @impl true
  def handle_call(:end_turn, _from, state) do
    new_state = State.advance_turn(state)
    broadcast(new_state)
    {:reply, new_state, new_state}
  end

  # --- Helpers ---

  defp put_targets(state, targets), do: Map.put(state, :valid_targets, targets)

  defp broadcast(state) do
    Phoenix.PubSub.broadcast(Gibbering.PubSub, topic(state.campaign_id), {:state_updated, state})
  end

  defp via(game_id), do: {:via, Registry, {Gibbering.GameRegistry, game_id}}
end
