defmodule GibberingTales.Rulesets.DnD5e.Predicate do
  @moduledoc """
  Recursive predicate evaluator for the closed vocabulary defined in
  docs/predicate-vocabulary.md.

  All 51 predicates are implemented here. The evaluator is a single
  pattern-match function; adding a new predicate means adding a new clause.

  Context shape:
    %{entity: entity_map, target: entity_map | nil,
      scene: scene_context, resolution: resolution_context | nil}
  """

  @doc "Evaluates predicate `pred` against `ctx` and returns a boolean."

  # ---------------------------------------------------------------------------
  # Group 1 — Structural Combinators
  # ---------------------------------------------------------------------------

  def eval({:always}, _ctx), do: true
  def eval({:never}, _ctx), do: false

  def eval({:all_of, preds}, ctx), do: Enum.all?(preds, &eval(&1, ctx))
  def eval({:any_of, preds}, ctx), do: Enum.any?(preds, &eval(&1, ctx))
  def eval({:not, pred}, ctx), do: not eval(pred, ctx)

  # ---------------------------------------------------------------------------
  # Group 2 — Entity-Local
  # ---------------------------------------------------------------------------

  def eval({:entity_type_is, type}, %{entity: e}),
    do: to_string(Map.get(e, :type)) == to_string(type)

  def eval({:entity_class_is, class}, %{entity: e}),
    do: to_string(Map.get(e, :class, "")) == to_string(class)

  def eval({:entity_race_is, race}, %{entity: e}),
    do: to_string(Map.get(e, :race, "")) == to_string(race)

  def eval({:entity_level_gte, n}, %{entity: e}),
    do: Map.get(e, :level, 1) >= n

  def eval({:entity_has_tag, tag}, %{entity: e}),
    do: to_string(tag) in Enum.map(Map.get(e, :tags, []), &to_string/1)

  def eval({:entity_hp_lte_fraction, fraction}, %{entity: e}) do
    max_hp = Map.get(e, :max_hp, 1)

    threshold =
      case fraction do
        :half -> 0.5
        :quarter -> 0.25
        _ -> 0.0
      end

    Map.get(e, :hp, 0) / max(max_hp, 1) <= threshold
  end

  def eval({:entity_has_resource, key}, %{entity: e}),
    do: (get_in(e, [:resources, key]) || 0) >= 1

  def eval({:entity_resource_gte, key, n}, %{entity: e}),
    do: (get_in(e, [:resources, key]) || 0) >= n

  def eval({:entity_wielding_property, prop}, %{entity: e}) do
    weapon = get_in(e, [:stats, "equipped_weapon"]) || %{}
    properties = Map.get(weapon, "properties", [])
    to_string(prop) in Enum.map(properties, &to_string/1)
  end

  def eval({:entity_armor_category, category}, %{entity: e}) do
    armor = get_in(e, [:stats, "equipped_armor"]) || %{}

    case Map.get(armor, "armor_category") do
      nil -> category == :none
      cat -> to_string(cat) == to_string(category)
    end
  end

  # ---------------------------------------------------------------------------
  # Group 3 — Entity Conditions
  # ---------------------------------------------------------------------------

  def eval({:entity_has_condition, key}, %{entity: e, scene: scene}) do
    conditions_for(e, scene) |> MapSet.member?(to_string(key))
  end

  def eval({:entity_concentrating_on, :any}, %{entity: e, scene: scene}) do
    conditions_for(e, scene) |> Enum.any?(&String.starts_with?(&1, "concentrating_"))
  end

  def eval({:entity_concentrating_on, spell_key}, %{entity: e, scene: scene}) do
    conditions_for(e, scene) |> MapSet.member?("concentrating_#{spell_key}")
  end

  def eval({:entity_is_incapacitated}, ctx) do
    eval(
      {:any_of,
       [
         {:entity_has_condition, :incapacitated},
         {:entity_has_condition, :stunned},
         {:entity_has_condition, :paralyzed},
         {:entity_has_condition, :unconscious},
         {:entity_has_condition, :petrified}
       ]},
      ctx
    )
  end

  # ---------------------------------------------------------------------------
  # Group 4 — Target State
  # ---------------------------------------------------------------------------

  def eval({:target_has_condition, key}, %{target: t, scene: scene}) when not is_nil(t) do
    conditions_for(t, scene) |> MapSet.member?(to_string(key))
  end

  def eval({:target_has_condition, _key}, _ctx), do: false

  def eval({:target_type_is, type}, %{target: t}) when not is_nil(t),
    do: to_string(Map.get(t, :type)) == to_string(type)

  def eval({:target_type_is, _}, _ctx), do: false

  def eval({:target_has_tag, tag}, %{target: t}) when not is_nil(t),
    do: to_string(tag) in Enum.map(Map.get(t, :tags, []), &to_string/1)

  def eval({:target_has_tag, _}, _ctx), do: false

  def eval({:target_hp_lte_fraction, fraction}, %{target: t}) when not is_nil(t) do
    max_hp = Map.get(t, :max_hp, 1)

    threshold =
      case fraction do
        :half -> 0.5
        :quarter -> 0.25
        _ -> 0.0
      end

    Map.get(t, :hp, 0) / max(max_hp, 1) <= threshold
  end

  def eval({:target_hp_lte_fraction, _}, _ctx), do: false

  def eval({:target_is_incapacitated}, ctx) do
    eval(
      {:any_of,
       [
         {:target_has_condition, :incapacitated},
         {:target_has_condition, :stunned},
         {:target_has_condition, :paralyzed},
         {:target_has_condition, :unconscious},
         {:target_has_condition, :petrified}
       ]},
      ctx
    )
  end

  def eval({:target_is_creature}, %{target: t}) when not is_nil(t),
    do: Map.get(t, :type) in ["hero", "monster", :hero, :monster]

  def eval({:target_is_creature}, _ctx), do: false

  # ---------------------------------------------------------------------------
  # Group 5 — Spatial
  # ---------------------------------------------------------------------------

  def eval({:entity_adjacent_to_target}, %{entity: e, target: t}) when not is_nil(t),
    do: chebyshev(e, t) <= 1

  def eval({:entity_adjacent_to_target}, _ctx), do: false

  def eval({:ally_adjacent_to_target}, %{entity: e, target: t, scene: scene})
      when not is_nil(t) do
    scene.entities
    |> Enum.any?(fn {_id, ally} ->
      ally != e and ally[:type] == e[:type] and chebyshev(ally, t) <= 1
    end)
  end

  def eval({:ally_adjacent_to_target}, _ctx), do: false

  def eval({:no_enemy_adjacent_to_entity}, %{entity: e, scene: scene}) do
    not Enum.any?(scene.entities, fn {_id, other} ->
      other[:type] != e[:type] and chebyshev(other, e) <= 1
    end)
  end

  def eval({:target_within_range, n_feet}, %{entity: e, target: t}) when not is_nil(t),
    do: chebyshev(e, t) * 5 <= n_feet

  def eval({:target_within_range, _}, _ctx), do: false

  # Cover predicates: engine doesn't model LoS yet — conservative false
  def eval({:entity_has_cover_from_target}, _ctx), do: false
  def eval({:target_has_cover_from_entity}, _ctx), do: false

  def eval({:entity_and_ally_flank_target}, %{entity: e, target: t, scene: scene})
      when not is_nil(t) do
    Enum.any?(scene.entities, fn {_id, ally} ->
      ally != e and ally[:type] == e[:type] and
        chebyshev(ally, t) <= 1 and
        opposite_sides?(e, ally, t)
    end)
  end

  def eval({:entity_and_ally_flank_target}, _ctx), do: false

  def eval({:entity_tile_has_tag, tile_tag}, %{entity: e, scene: scene}) do
    tile = Map.get(scene.grid || %{}, {e[:x], e[:y]}, %{})
    tile_tags = Map.get(tile, :tags, [])
    to_string(tile_tag) in Enum.map(tile_tags, &to_string/1)
  end

  # ---------------------------------------------------------------------------
  # Group 6 — Resolution Context (false when resolution is nil)
  # ---------------------------------------------------------------------------

  def eval({:attack_type_is, _}, %{resolution: nil}), do: false

  def eval({:attack_type_is, type}, %{resolution: r}),
    do: r[:attack_type] == type

  def eval({:damage_type_is, _}, %{resolution: nil}), do: false

  def eval({:damage_type_is, type}, %{resolution: r}),
    do: r[:damage_type] == type

  def eval({:is_critical_hit}, %{resolution: nil}), do: false

  def eval({:is_critical_hit}, %{resolution: r}),
    do: r[:is_critical] == true

  def eval({:weapon_has_property, _}, %{resolution: nil}), do: false

  def eval({:weapon_has_property, prop}, %{resolution: r}) do
    weapon = r[:weapon] || %{}
    properties = Map.get(weapon, "properties", [])
    to_string(prop) in Enum.map(properties, &to_string/1)
  end

  def eval({:spell_school_is, _}, %{resolution: nil}), do: false

  def eval({:spell_school_is, school}, %{resolution: r}) do
    spell = r[:spell]
    not is_nil(spell) and spell[:school] == school
  end

  def eval({:spell_level_gte, _}, %{resolution: nil}), do: false

  def eval({:spell_level_gte, n}, %{resolution: r}) do
    spell = r[:spell]
    not is_nil(spell) and Map.get(spell, :level, 0) >= n
  end

  def eval({:saving_throw_ability_is, _}, %{resolution: nil}), do: false

  def eval({:saving_throw_ability_is, ability}, %{resolution: r}),
    do: r[:saving_throw_ability] == ability

  def eval({:is_bonus_action_attack}, %{resolution: nil}), do: false

  def eval({:is_bonus_action_attack}, %{resolution: r}),
    do: r[:economy_slot] == :bonus_action

  def eval({:first_attack_in_resolution}, %{resolution: nil}), do: false

  def eval({:first_attack_in_resolution}, %{resolution: r}),
    do: Map.get(r, :attack_index, 0) == 0

  # ---------------------------------------------------------------------------
  # Group 7 — Turn History (true outside :in_combat)
  # ---------------------------------------------------------------------------

  def eval({:first_attack_this_turn}, %{scene: %{phase: phase}})
      when phase != :in_combat,
      do: true

  def eval({:first_attack_this_turn}, %{entity: e, scene: scene}) do
    entity_id = e[:id]

    not Enum.any?(scene.event_log || [], fn ev ->
      ev[:type] == :attack_rolled and ev[:actor_id] == entity_id and
        ev[:turn] == scene[:current_turn]
    end)
  end

  def eval({:has_moved_this_turn}, %{scene: %{phase: phase}})
      when phase != :in_combat,
      do: true

  def eval({:has_moved_this_turn}, %{entity: e, scene: scene}) do
    entity_id = e[:id]

    Enum.any?(scene.event_log || [], fn ev ->
      ev[:type] == :entity_moved and ev[:actor_id] == entity_id and
        ev[:turn] == scene[:current_turn]
    end)
  end

  def eval({:has_used_action_this_turn}, %{scene: %{phase: phase}})
      when phase != :in_combat,
      do: true

  def eval({:has_used_action_this_turn}, %{entity: e, scene: scene}) do
    entity_id = e[:id]

    Enum.any?(scene.event_log || [], fn ev ->
      ev[:type] == :action_used and ev[:actor_id] == entity_id and
        ev[:turn] == scene[:current_turn]
    end)
  end

  def eval({:has_used_bonus_action_this_turn}, %{scene: %{phase: phase}})
      when phase != :in_combat,
      do: true

  def eval({:has_used_bonus_action_this_turn}, %{entity: e, scene: scene}) do
    entity_id = e[:id]

    Enum.any?(scene.event_log || [], fn ev ->
      ev[:type] == :bonus_action_used and ev[:actor_id] == entity_id and
        ev[:turn] == scene[:current_turn]
    end)
  end

  def eval({:took_damage_this_turn}, %{scene: %{phase: phase}})
      when phase != :in_combat,
      do: true

  def eval({:took_damage_this_turn}, %{entity: e, scene: scene}) do
    entity_id = e[:id]

    Enum.any?(scene.event_log || [], fn ev ->
      ev[:type] == :damage_received and ev[:target_id] == entity_id and
        ev[:turn] == scene[:current_turn]
    end)
  end

  def eval({:took_damage_type_this_turn, _type}, %{scene: %{phase: phase}})
      when phase != :in_combat,
      do: true

  def eval({:took_damage_type_this_turn, dmg_type}, %{entity: e, scene: scene}) do
    entity_id = e[:id]

    Enum.any?(scene.event_log || [], fn ev ->
      ev[:type] == :damage_received and ev[:target_id] == entity_id and
        ev[:damage_type] == dmg_type and ev[:turn] == scene[:current_turn]
    end)
  end

  def eval({:entity_was_attacked_this_round}, %{scene: %{phase: phase}})
      when phase != :in_combat,
      do: true

  def eval({:entity_was_attacked_this_round}, %{entity: e, scene: scene}) do
    entity_id = e[:id]

    Enum.any?(scene.event_log || [], fn ev ->
      ev[:type] == :attack_targeted and ev[:target_id] == entity_id and
        ev[:round] == scene[:current_round]
    end)
  end

  def eval({:round_number_gte, _n}, %{scene: %{phase: phase}})
      when phase != :in_combat,
      do: true

  def eval({:round_number_gte, n}, %{scene: scene}),
    do: Map.get(scene, :current_round, 0) >= n

  # ---------------------------------------------------------------------------
  # Group 8 — Scene State
  # ---------------------------------------------------------------------------

  def eval({:scene_phase_is, phase}, %{scene: scene}),
    do: scene.phase == phase

  def eval({:entity_has_active_effect, key}, %{entity: e, scene: scene}) do
    entity_id = e[:id]

    Enum.any?(scene.active_effects || [], fn ae ->
      ae[:key] == key and ae[:entity_id] == entity_id
    end)
  end

  def eval({:effect_source_is, source}, %{scene: scene}) do
    # Checks the source of the currently-being-evaluated active effect.
    # The scene carries :current_effect_source when iterating active effects.
    Map.get(scene, :current_effect_source) == source
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  defp chebyshev(a, b),
    do:
      max(abs(Map.get(a, :x, 0) - Map.get(b, :x, 0)), abs(Map.get(a, :y, 0) - Map.get(b, :y, 0)))

  defp opposite_sides?(entity, ally, target) do
    # True when entity and ally are on opposite sides of target along any axis.
    ex = Map.get(entity, :x, 0) - Map.get(target, :x, 0)
    ax = Map.get(ally, :x, 0) - Map.get(target, :x, 0)
    ey = Map.get(entity, :y, 0) - Map.get(target, :y, 0)
    ay = Map.get(ally, :y, 0) - Map.get(target, :y, 0)
    ex * ax < 0 or ey * ay < 0
  end

  defp conditions_for(entity, scene) do
    entity_id = entity[:id]

    (scene.active_effects || [])
    |> Enum.filter(&(&1[:entity_id] == entity_id))
    |> Enum.flat_map(&Map.get(&1, :conditions, []))
    |> Enum.concat(Map.get(entity, :conditions, []))
    |> Enum.map(&to_string/1)
    |> MapSet.new()
  end
end
