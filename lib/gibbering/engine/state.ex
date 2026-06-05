defmodule Gibbering.Engine.State do
  alias Gibbering.Campaign
  alias Gibbering.Rulesets.DnD5e.Stats

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
    :active_index
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
      active_index: 0
    }
  end

  def active_hero_id(%__MODULE__{turn_order: []}), do: nil
  def active_hero_id(%__MODULE__{turn_order: order, active_index: idx}), do: Enum.at(order, idx)

  def advance_turn(%__MODULE__{} = state) do
    next = rem(state.active_index + 1, max(length(state.turn_order), 1))
    %{state | active_index: next, selected_id: nil, valid_moves: []}
  end
end
