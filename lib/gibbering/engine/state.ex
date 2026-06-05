defmodule Gibbering.Engine.State do
  alias Gibbering.Campaign
  alias Gibbering.Rulesets.DnD5e.Stats

  @type scene_phase :: :lobby | :exploration | :initiative_rolling | :in_combat | :paused

  @valid_transitions %{
    lobby: [:exploration, :paused],
    exploration: [:initiative_rolling, :in_combat, :paused],
    initiative_rolling: [:in_combat, :paused],
    in_combat: [:exploration, :paused]
  }

  defstruct [
    :campaign_id,
    :map_width,
    :map_height,
    :tile_size,
    # %{{x, y} => %{texture: string, walkable: bool}}
    :grid_tiles,
    # %{id => %{name, type, sprite, x, y, hp, max_hp, tags, stats}}
    :entities,
    # integer | nil
    :selected_id,
    # [{x, y}]
    :valid_moves,
    # [entity_id] — hero ids in sequence
    :turn_order,
    # index into turn_order
    :active_index,
    # scene_phase() — current phase of the scene
    phase: :lobby,
    # scene_phase() | nil — phase before entering :paused
    previous_phase: nil,
    # module implementing Gibbering.Ruleset behaviour
    ruleset: Gibbering.Rulesets.DnD5e
  ]

  def from_campaign(%Campaign{} = campaign) do
    tiles =
      campaign.tiles
      |> Map.new(fn t ->
        {{t.x, t.y}, %{texture: t.texture, walkable: t.walkable, decoration: t.decoration}}
      end)

    entities =
      campaign.entities
      |> Map.new(fn e ->
        base = %{
          name: e.name,
          type: e.type,
          sprite: e.sprite,
          race: e.race || "human",
          class: e.class || "fighter",
          x: e.x,
          y: e.y,
          hp: e.hp,
          max_hp: e.max_hp,
          level: e.level,
          temp_hp: e.temp_hp,
          tags: e.tags,
          stats: e.stats
        }

        {e.id, Stats.hydrate_entity(base)}
      end)

    hero_ids =
      campaign.entities
      |> Enum.filter(&(&1.type == "hero"))
      |> Enum.map(& &1.id)

    %__MODULE__{
      campaign_id: campaign.id,
      map_width: campaign.map_width,
      map_height: campaign.map_height,
      tile_size: campaign.tile_size,
      grid_tiles: tiles,
      entities: entities,
      selected_id: nil,
      valid_moves: [],
      turn_order: hero_ids,
      active_index: 0,
      phase: :lobby,
      previous_phase: nil,
      ruleset: Gibbering.Rulesets.DnD5e
    }
  end

  @doc """
  Transitions to `new_phase` if the transition is valid.
  From `:paused`, the only valid target is `previous_phase`.
  Returns `{:ok, new_state}` or `{:error, reason}`.
  """
  def transition_phase(%__MODULE__{phase: same} = state, same), do: {:ok, state}

  def transition_phase(%__MODULE__{phase: :paused, previous_phase: prev} = state, new_phase) do
    if new_phase == prev do
      {:ok, %{state | phase: new_phase, previous_phase: nil}}
    else
      {:error, "cannot leave :paused to #{new_phase}; expected #{prev}"}
    end
  end

  def transition_phase(%__MODULE__{phase: current} = state, new_phase) do
    if new_phase in Map.get(@valid_transitions, current, []) do
      {:ok, %{state | previous_phase: current, phase: new_phase}}
    else
      {:error, "invalid transition: #{current} → #{new_phase}"}
    end
  end

  @doc "Forces a phase transition without validation — for DM override calls."
  def force_transition_phase(%__MODULE__{phase: current} = state, new_phase) do
    {:ok, %{state | previous_phase: current, phase: new_phase}}
  end

  def active_hero_id(%__MODULE__{turn_order: []}), do: nil
  def active_hero_id(%__MODULE__{turn_order: order, active_index: idx}), do: Enum.at(order, idx)

  def advance_turn(%__MODULE__{} = state) do
    next = rem(state.active_index + 1, max(length(state.turn_order), 1))
    %{state | active_index: next, selected_id: nil, valid_moves: []}
  end
end
