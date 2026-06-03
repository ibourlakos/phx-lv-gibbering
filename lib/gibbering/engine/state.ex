defmodule Gibbering.Engine.State do
  alias Gibbering.Campaign

  defstruct [
    :campaign_id,
    :map_width,
    :map_height,
    :tile_size,
    :grid_tiles,   # %{{x, y} => %{texture: string, walkable: bool}}
    :entities,     # %{id => %{name, type, sprite, x, y, hp, max_hp, tags, stats}}
    :selected_id,  # integer | nil
    :valid_moves,  # [{x, y}]
    :turn_order,   # [entity_id] — hero ids in sequence
    :active_index  # index into turn_order
  ]

  def from_campaign(%Campaign{} = campaign) do
    tiles =
      campaign.tiles
      |> Map.new(fn t -> {{t.x, t.y}, %{texture: t.texture, walkable: t.walkable}} end)

    entities =
      campaign.entities
      |> Map.new(fn e ->
        {e.id, %{
          name: e.name,
          type: e.type,
          sprite: e.sprite,
          x: e.x,
          y: e.y,
          hp: e.hp,
          max_hp: e.max_hp,
          tags: e.tags,
          stats: e.stats
        }}
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

  def active_hero_id(%__MODULE__{turn_order: [], }), do: nil
  def active_hero_id(%__MODULE__{turn_order: order, active_index: idx}), do: Enum.at(order, idx)

  def advance_turn(%__MODULE__{} = state) do
    next = rem(state.active_index + 1, max(length(state.turn_order), 1))
    %{state | active_index: next, selected_id: nil, valid_moves: []}
  end
end
