defmodule Gibbering.Engine.Rules do
  alias Gibbering.Engine.State

  @doc "Returns [{x,y}] the entity can move to this turn."
  def valid_moves(%State{} = state, entity_id) do
    entity = state.entities[entity_id]
    max_tiles = div(Map.get(entity.stats, "speed", 30), 5)

    for x <- (entity.x - max_tiles)..(entity.x + max_tiles),
        y <- (entity.y - max_tiles)..(entity.y + max_tiles),
        {x, y} != {entity.x, entity.y},
        in_bounds?(x, y, state),
        manhattan(entity.x, entity.y, x, y) <= max_tiles,
        walkable?(state, x, y),
        not occupied_by_hero?(state, x, y),
        do: {x, y}
  end

  @doc "Returns entity ids that the active entity can attack (adjacent, destructible or enemy)."
  def valid_targets(%State{} = state, entity_id) do
    entity = state.entities[entity_id]

    state.entities
    |> Enum.filter(fn {id, target} ->
      id != entity_id and
        manhattan(entity.x, entity.y, target.x, target.y) <= 1 and
        ("destructible" in target.tags or target.type == "monster")
    end)
    |> Enum.map(fn {id, _} -> id end)
  end

  @doc "Apply a basic melee attack. Returns updated state."
  def attack(%State{} = state, _attacker_id, target_id) do
    target = state.entities[target_id]
    damage = Enum.random(1..6)
    new_hp = max(target.hp - damage, 0)

    state
    |> put_entity_hp(target_id, new_hp)
    |> maybe_destroy(target_id, new_hp)
  end

  defp put_entity_hp(state, id, hp) do
    updated = Map.put(state.entities[id], :hp, hp)
    %{state | entities: Map.put(state.entities, id, updated)}
  end

  defp maybe_destroy(state, id, 0) do
    entity = state.entities[id]
    new_entities = Map.delete(state.entities, id)

    new_tiles =
      if "destructible" in entity.tags do
        Map.put(state.grid_tiles, {entity.x, entity.y}, %{texture: "rubble", walkable: true})
      else
        state.grid_tiles
      end

    %{state | entities: new_entities, grid_tiles: new_tiles}
  end

  defp maybe_destroy(state, _id, _hp), do: state

  defp manhattan(x1, y1, x2, y2), do: abs(x1 - x2) + abs(y1 - y2)

  defp in_bounds?(x, y, state),
    do: x >= 0 and x < state.map_width and y >= 0 and y < state.map_height

  defp walkable?(state, x, y) do
    case Map.get(state.grid_tiles, {x, y}) do
      nil -> false
      tile -> tile.walkable
    end
  end

  defp occupied_by_hero?(state, x, y) do
    Enum.any?(state.entities, fn {_, e} -> e.type == "hero" and e.x == x and e.y == y end)
  end
end
