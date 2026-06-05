defmodule Gibbering.Engine.Rules do
  alias Gibbering.Engine.State
  alias Gibbering.Rulesets.DnD5e.Stats

  @doc "Returns [{x,y}] the entity can move to this turn based on remaining movement."
  def valid_moves(%State{} = state, entity_id) do
    entity = state.entities[entity_id]
    movement_remaining = get_in(entity, [:action_economy, :movement_remaining])
    speed_ft = movement_remaining || Map.get(entity.stats || %{}, "speed", 30)
    max_tiles = div(speed_ft, 5)

    for x <- (entity.x - max_tiles)..(entity.x + max_tiles),
        y <- (entity.y - max_tiles)..(entity.y + max_tiles),
        {x, y} != {entity.x, entity.y},
        in_bounds?(x, y, state),
        chebyshev(entity.x, entity.y, x, y) <= max_tiles,
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
        chebyshev(entity.x, entity.y, target.x, target.y) <= 1 and
        ("destructible" in target.tags or target.type == "monster")
    end)
    |> Enum.map(fn {id, _} -> id end)
  end

  @doc """
  Resolve a melee attack from attacker against target.

  Validates that the attacker has an `:action` available, then consumes it.
  Returns `{result, new_state, roll_details}` where result is `:hit | :miss | :critical`,
  or `{:error, reason}` when the action economy check fails.

  Pass `roll: n` in opts to fix the d20 value (for testing).
  """
  def attack(%State{} = state, attacker_id, target_id, opts \\ []) do
    with {:ok, state} <- State.consume_action(state, attacker_id, :action) do
      do_attack(state, attacker_id, target_id, opts)
    end
  end

  defp do_attack(%State{} = state, attacker_id, target_id, opts) do
    attacker = state.entities[attacker_id]
    target = state.entities[target_id]

    roll = Keyword.get(opts, :roll, Enum.random(1..20))
    bonus = attack_bonus_for(attacker)
    target_ac = Map.get(target, :armor_class, 10)

    {hit, critical} =
      cond do
        roll == 20 -> {true, true}
        roll == 1 -> {false, false}
        roll + bonus >= target_ac -> {true, false}
        true -> {false, false}
      end

    {damage, new_state} =
      if hit do
        dmg = roll_damage(attacker, critical)
        new_hp = max(target.hp - dmg, 0)
        s = state |> put_entity_hp(target_id, new_hp) |> maybe_destroy(target_id, new_hp)
        {dmg, s}
      else
        {nil, state}
      end

    result = if critical, do: :critical, else: if(hit, do: :hit, else: :miss)

    details = %{
      roll: roll,
      bonus: bonus,
      total: roll + bonus,
      target_ac: target_ac,
      hit: hit,
      critical: critical,
      damage: damage
    }

    {result, new_state, details}
  end

  defp attack_bonus_for(attacker) do
    prof =
      Map.get(attacker, :proficiency_bonus, Stats.proficiency_bonus(Map.get(attacker, :level, 1)))

    mods = Map.get(attacker, :ability_modifiers, %{})
    str_mod = Map.get(mods, "strength", 0)
    str_mod + prof
  end

  defp roll_damage(attacker, critical) do
    weapon = get_in(attacker, [:stats, "equipped_weapon"])
    {dice_count, die_size} = parse_dice(weapon["damage_dice"] || "1d4")
    count = if critical, do: dice_count * 2, else: dice_count
    Enum.sum(for _ <- 1..count, do: Enum.random(1..die_size))
  end

  defp parse_dice(dice_str) do
    [count, size] = String.split(dice_str, "d")
    {String.to_integer(count), String.to_integer(size)}
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

  defp chebyshev(x1, y1, x2, y2), do: max(abs(x1 - x2), abs(y1 - y2))

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
