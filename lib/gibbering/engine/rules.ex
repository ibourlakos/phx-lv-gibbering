defmodule Gibbering.Engine.Rules do
  @moduledoc "Core combat rule resolution: movement, attacks, spell casting, and saving throws."

  alias Gibbering.Engine.State
  alias Gibbering.Rulesets.DnD5e.Stats
  alias Gibbering.Data.{Classes, Spells}

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

  @doc """
  Returns entity ids within range of `spell_key` cast by `caster_id`.
  For single-target spells this is all enemies in range; AoE spells return
  the same set (area resolution handled separately at cast time).
  Returns `[]` when the spell key is not found.
  """
  def valid_spell_targets(%State{} = state, caster_id, spell_key) do
    spell = Spells.get(spell_key)

    if is_nil(spell) do
      []
    else
      caster = state.entities[caster_id]
      max_tiles = spell_range_tiles(spell.range)

      state.entities
      |> Enum.filter(fn {id, target} ->
        id != caster_id and
          chebyshev(caster.x, caster.y, target.x, target.y) <= max_tiles and
          ("destructible" in target.tags or target.type == "monster")
      end)
      |> Enum.map(fn {id, _} -> id end)
    end
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

  @doc """
  Roll a saving throw for `target_id` against `dc` using `ability`.

  Returns `{:save, details}` when total >= dc, else `{:fail, details}`.
  Pass `roll: n` in opts to fix the d20 value (for testing).
  """
  def saving_throw(%State{} = state, target_id, ability, dc, opts \\ []) do
    entity = state.entities[target_id]
    roll = Keyword.get(opts, :roll, Enum.random(1..20))
    ability_str = to_string(ability)

    ability_mod =
      Map.get(
        Map.get(entity, :ability_modifiers, %{}),
        ability_str,
        Stats.ability_modifier(get_in(entity, [:stats, ability_str]) || 10)
      )

    prof =
      if proficient_in_save?(entity, ability_str),
        do: Stats.proficiency_bonus(Map.get(entity, :level, 1)),
        else: 0

    total = roll + ability_mod + prof

    details = %{
      roll: roll,
      modifier: ability_mod + prof,
      total: total,
      dc: dc,
      ability: ability,
      proficient: prof > 0
    }

    if total >= dc, do: {:save, details}, else: {:fail, details}
  end

  @doc """
  Resolve a spell cast from `caster_id` targeting `target_id`.

  Validates and consumes the `:action` slot (and a spell slot for level 1+).
  Returns `{result, new_state, details}` where result is `:hit | :miss | :critical`,
  or `{:error, reason}` when resource checks fail.

  Supported `attack_type` values:
    `:ranged_attack` — rolls d20 + spellcasting bonus vs target AC
    `:auto`          — always hits, rolls damage

  All other attack types (`:save`, `:aoe`, `:utility`, `:touch`) record the
  cast and return `:hit` without applying damage — full resolution is deferred
  to future issues (#48 saving throws, #34 AoE).

  Pass `roll: n` in opts to fix the d20 value (for testing).
  """
  def cast_spell(%State{} = state, caster_id, spell_key, target_id, opts \\ []) do
    spell = Spells.get(spell_key)

    with false <- is_nil(spell),
         {:ok, state} <- consume_spell_resources(state, caster_id, spell.level) do
      do_cast(state, caster_id, spell, target_id, opts)
    else
      true -> {:error, :unknown_spell}
      err -> err
    end
  end

  defp consume_spell_resources(state, caster_id, 0) do
    State.consume_action(state, caster_id, :action)
  end

  defp consume_spell_resources(state, caster_id, level) do
    with {:ok, s1} <- State.consume_action(state, caster_id, :action),
         {:ok, s2} <- State.consume_spell_slot(s1, caster_id, level) do
      {:ok, s2}
    end
  end

  defp do_cast(state, caster_id, spell, target_id, opts) do
    caster = state.entities[caster_id]
    target = state.entities[target_id]

    case spell.effect.attack_type do
      :ranged_attack ->
        roll = Keyword.get(opts, :roll, Enum.random(1..20))
        bonus = spell_attack_bonus(caster)
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
            dmg = roll_spell_damage(spell, critical)
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

      :auto ->
        damage = roll_spell_damage(spell, false)
        new_hp = max(target.hp - damage, 0)
        new_state = state |> put_entity_hp(target_id, new_hp) |> maybe_destroy(target_id, new_hp)
        {:hit, new_state, %{hit: true, damage: damage}}

      :save ->
        dc = Stats.spell_dc(caster)
        {save_result, save_details} = saving_throw(state, target_id, spell.effect.save, dc, opts)

        {damage, new_state} =
          case save_result do
            :fail ->
              dmg = roll_spell_damage(spell, false)
              new_hp = max(target.hp - dmg, 0)
              s = state |> put_entity_hp(target_id, new_hp) |> maybe_destroy(target_id, new_hp)
              {dmg, s}

            :save ->
              dmg = div(roll_spell_damage(spell, false), 2)
              new_hp = max(target.hp - dmg, 0)
              s = state |> put_entity_hp(target_id, new_hp) |> maybe_destroy(target_id, new_hp)
              {dmg, s}
          end

        {:hit, new_state,
         %{hit: true, save_result: save_result, damage: damage, save: save_details}}

      _other ->
        # aoe / utility / touch — no damage applied yet
        {:hit, state, %{hit: true, damage: nil}}
    end
  end

  defp proficient_in_save?(entity, ability_str) do
    class = Map.get(entity, :class, "")
    class_data = Classes.seed_data()[class] || %{}
    ability_str in Map.get(class_data, :saving_throws, [])
  end

  defp spell_attack_bonus(caster) do
    prof =
      Map.get(caster, :proficiency_bonus, Stats.proficiency_bonus(Map.get(caster, :level, 1)))

    mods = Map.get(caster, :ability_modifiers, %{})
    # Spellcasting ability: wizards use INT, clerics WIS — default to INT
    int_mod = Map.get(mods, "intelligence", 0)
    int_mod + prof
  end

  defp roll_spell_damage(spell, critical) do
    dice_str = spell.effect.damage_dice

    if is_nil(dice_str) do
      0
    else
      {count, size, flat} = parse_spell_dice(dice_str)
      roll_count = if critical, do: count * 2, else: count
      Enum.sum(for _ <- 1..max(roll_count, 1), do: Enum.random(1..size)) + flat
    end
  end

  defp parse_spell_dice(dice_str) do
    case String.split(dice_str, ~r/[d+]/) do
      [count, size, flat] ->
        {String.to_integer(count), String.to_integer(size), String.to_integer(flat)}

      [count, size] ->
        {String.to_integer(count), String.to_integer(size), 0}
    end
  end

  defp spell_range_tiles(:touch), do: 1
  defp spell_range_tiles(:self), do: 0
  defp spell_range_tiles({:feet, n}), do: div(n, 5)
  defp spell_range_tiles(_), do: 0

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
    do: x >= 0 and x < state.x_extent and y >= 0 and y < state.y_extent

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
