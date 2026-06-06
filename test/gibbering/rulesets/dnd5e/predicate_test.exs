defmodule Gibbering.Rulesets.DnD5e.PredicateTest do
  use ExUnit.Case, async: true

  alias Gibbering.Rulesets.DnD5e.Predicate

  # Minimal eval context for tests that only need one or two fields.
  defp ctx(overrides \\ []) do
    base = %{
      entity: %{
        id: 1,
        type: "hero",
        class: "fighter",
        race: "human",
        level: 1,
        hp: 10,
        max_hp: 10,
        x: 0,
        y: 0,
        tags: [],
        stats: %{},
        resources: %{},
        conditions: []
      },
      target: nil,
      scene: %{
        entities: %{},
        grid: %{},
        active_effects: [],
        event_log: [],
        phase: :in_combat,
        current_turn: 1,
        current_round: 1
      },
      resolution: nil
    }

    Enum.reduce(overrides, base, fn {k, v}, acc -> Map.put(acc, k, v) end)
  end

  defp with_entity(ctx, attrs), do: %{ctx | entity: Map.merge(ctx.entity, Map.new(attrs))}

  defp with_target(ctx, attrs),
    do: %{
      ctx
      | target:
          Map.merge(
            %{id: 99, type: "monster", x: 1, y: 1, hp: 5, max_hp: 5, tags: [], conditions: []},
            Map.new(attrs)
          )
    }

  defp with_resolution(ctx, attrs), do: %{ctx | resolution: Map.new(attrs)}
  defp with_scene(ctx, attrs), do: %{ctx | scene: Map.merge(ctx.scene, Map.new(attrs))}

  # ---------------------------------------------------------------------------
  # Group 1 — Structural Combinators
  # ---------------------------------------------------------------------------

  describe "Group 1 — structural combinators" do
    test "{:always} is always true" do
      assert Predicate.eval({:always}, ctx())
    end

    test "{:never} is always false" do
      refute Predicate.eval({:never}, ctx())
    end

    test "{:all_of, []} is true" do
      assert Predicate.eval({:all_of, []}, ctx())
    end

    test "{:all_of, preds} is true when all hold" do
      assert Predicate.eval({:all_of, [{:always}, {:always}]}, ctx())
    end

    test "{:all_of, preds} is false when any fails" do
      refute Predicate.eval({:all_of, [{:always}, {:never}]}, ctx())
    end

    test "{:any_of, preds} is true when at least one holds" do
      assert Predicate.eval({:any_of, [{:never}, {:always}]}, ctx())
    end

    test "{:any_of, []} is false" do
      refute Predicate.eval({:any_of, []}, ctx())
    end

    test "{:not, pred} negates" do
      assert Predicate.eval({:not, {:never}}, ctx())
      refute Predicate.eval({:not, {:always}}, ctx())
    end
  end

  # ---------------------------------------------------------------------------
  # Group 2 — Entity-Local
  # ---------------------------------------------------------------------------

  describe "Group 2 — entity-local" do
    test "{:entity_type_is, type}" do
      assert Predicate.eval({:entity_type_is, :hero}, with_entity(ctx(), type: "hero"))
      refute Predicate.eval({:entity_type_is, :monster}, with_entity(ctx(), type: "hero"))
    end

    test "{:entity_class_is, class}" do
      assert Predicate.eval({:entity_class_is, :rogue}, with_entity(ctx(), class: "rogue"))
      refute Predicate.eval({:entity_class_is, :wizard}, with_entity(ctx(), class: "rogue"))
    end

    test "{:entity_race_is, race}" do
      assert Predicate.eval({:entity_race_is, :elf}, with_entity(ctx(), race: "elf"))
      refute Predicate.eval({:entity_race_is, :dwarf}, with_entity(ctx(), race: "elf"))
    end

    test "{:entity_level_gte, n}" do
      assert Predicate.eval({:entity_level_gte, 3}, with_entity(ctx(), level: 3))
      assert Predicate.eval({:entity_level_gte, 3}, with_entity(ctx(), level: 5))
      refute Predicate.eval({:entity_level_gte, 3}, with_entity(ctx(), level: 2))
    end

    test "{:entity_has_tag, tag}" do
      assert Predicate.eval({:entity_has_tag, :undead}, with_entity(ctx(), tags: ["undead"]))
      refute Predicate.eval({:entity_has_tag, :undead}, with_entity(ctx(), tags: []))
    end

    test "{:entity_hp_lte_fraction, :half}" do
      at_half = with_entity(ctx(), hp: 5, max_hp: 10)
      above_half = with_entity(ctx(), hp: 6, max_hp: 10)
      assert Predicate.eval({:entity_hp_lte_fraction, :half}, at_half)
      refute Predicate.eval({:entity_hp_lte_fraction, :half}, above_half)
    end

    test "{:entity_has_resource, key}" do
      e = with_entity(ctx(), resources: %{rage_charges: 2})
      assert Predicate.eval({:entity_has_resource, :rage_charges}, e)
      refute Predicate.eval({:entity_has_resource, :second_wind}, e)
    end

    test "{:entity_resource_gte, key, n}" do
      e = with_entity(ctx(), resources: %{rage_charges: 3})
      assert Predicate.eval({:entity_resource_gte, :rage_charges, 3}, e)
      refute Predicate.eval({:entity_resource_gte, :rage_charges, 4}, e)
    end

    test "{:entity_wielding_property, prop}" do
      e = with_entity(ctx(), stats: %{"equipped_weapon" => %{"properties" => ["finesse"]}})
      assert Predicate.eval({:entity_wielding_property, :finesse}, e)
      refute Predicate.eval({:entity_wielding_property, :heavy}, e)
    end

    test "{:entity_armor_category, category}" do
      e = with_entity(ctx(), stats: %{"equipped_armor" => %{"armor_category" => "heavy"}})
      assert Predicate.eval({:entity_armor_category, :heavy}, e)
      refute Predicate.eval({:entity_armor_category, :light}, e)
    end
  end

  # ---------------------------------------------------------------------------
  # Group 3 — Entity Conditions
  # ---------------------------------------------------------------------------

  describe "Group 3 — entity conditions" do
    test "{:entity_has_condition, key} reads from entity.conditions" do
      e = with_entity(ctx(), conditions: ["raging"])
      assert Predicate.eval({:entity_has_condition, :raging}, e)
      refute Predicate.eval({:entity_has_condition, :paralyzed}, e)
    end

    test "{:entity_has_condition, key} also reads from scene active_effects" do
      scene_ctx =
        ctx()
        |> with_scene(active_effects: [%{entity_id: 1, conditions: ["poisoned"]}])

      assert Predicate.eval({:entity_has_condition, :poisoned}, scene_ctx)
    end

    test "{:entity_is_incapacitated} matches incapacitating conditions" do
      assert Predicate.eval(
               {:entity_is_incapacitated},
               with_entity(ctx(), conditions: ["stunned"])
             )

      refute Predicate.eval(
               {:entity_is_incapacitated},
               with_entity(ctx(), conditions: ["raging"])
             )
    end
  end

  # ---------------------------------------------------------------------------
  # Group 4 — Target State
  # ---------------------------------------------------------------------------

  describe "Group 4 — target state" do
    test "{:target_has_condition, key}" do
      c = ctx() |> with_target(conditions: ["poisoned"])
      assert Predicate.eval({:target_has_condition, :poisoned}, c)
      refute Predicate.eval({:target_has_condition, :blinded}, c)
    end

    test "{:target_has_condition} is false with no target" do
      refute Predicate.eval({:target_has_condition, :poisoned}, ctx())
    end

    test "{:target_type_is, type}" do
      c = ctx() |> with_target(type: "monster")
      assert Predicate.eval({:target_type_is, :monster}, c)
      refute Predicate.eval({:target_type_is, :hero}, c)
    end

    test "{:target_is_creature} is true for hero/monster, false for object" do
      assert Predicate.eval({:target_is_creature}, ctx() |> with_target(type: "hero"))
      assert Predicate.eval({:target_is_creature}, ctx() |> with_target(type: "monster"))
      refute Predicate.eval({:target_is_creature}, ctx() |> with_target(type: "object"))
    end

    test "{:target_hp_lte_fraction} false with no target" do
      refute Predicate.eval({:target_hp_lte_fraction, :half}, ctx())
    end
  end

  # ---------------------------------------------------------------------------
  # Group 5 — Spatial
  # ---------------------------------------------------------------------------

  describe "Group 5 — spatial" do
    test "{:entity_adjacent_to_target} within 1 tile" do
      c = ctx() |> with_entity(x: 0, y: 0) |> with_target(x: 1, y: 0)
      assert Predicate.eval({:entity_adjacent_to_target}, c)
    end

    test "{:entity_adjacent_to_target} false when 2+ tiles away" do
      c = ctx() |> with_entity(x: 0, y: 0) |> with_target(x: 2, y: 0)
      refute Predicate.eval({:entity_adjacent_to_target}, c)
    end

    test "{:entity_adjacent_to_target} false with no target" do
      refute Predicate.eval({:entity_adjacent_to_target}, ctx())
    end

    test "{:target_within_range, n_feet}" do
      c = ctx() |> with_entity(x: 0, y: 0) |> with_target(x: 3, y: 0)
      assert Predicate.eval({:target_within_range, 30}, c)
      refute Predicate.eval({:target_within_range, 10}, c)
    end

    test "{:no_enemy_adjacent_to_entity} when no nearby enemies" do
      scene = %{
        entities: %{2 => %{type: "monster", x: 5, y: 5}},
        grid: %{},
        active_effects: [],
        event_log: [],
        phase: :in_combat,
        current_turn: 1,
        current_round: 1
      }

      c = %{ctx() | scene: scene} |> with_entity(x: 0, y: 0)
      assert Predicate.eval({:no_enemy_adjacent_to_entity}, c)
    end
  end

  # ---------------------------------------------------------------------------
  # Group 6 — Resolution Context
  # ---------------------------------------------------------------------------

  describe "Group 6 — resolution context" do
    test "all Group 6 predicates return false when resolution is nil" do
      preds = [
        {:attack_type_is, :melee},
        {:damage_type_is, :slashing},
        {:is_critical_hit},
        {:weapon_has_property, :finesse},
        {:spell_school_is, :evocation},
        {:spell_level_gte, 1},
        {:saving_throw_ability_is, :dexterity},
        {:is_bonus_action_attack},
        {:first_attack_in_resolution}
      ]

      for pred <- preds do
        refute Predicate.eval(pred, ctx()),
               "expected #{inspect(pred)} to be false with nil resolution"
      end
    end

    test "{:attack_type_is, type} with resolution" do
      c = with_resolution(ctx(), attack_type: :melee)
      assert Predicate.eval({:attack_type_is, :melee}, c)
      refute Predicate.eval({:attack_type_is, :ranged}, c)
    end

    test "{:is_critical_hit} with resolution" do
      assert Predicate.eval({:is_critical_hit}, with_resolution(ctx(), is_critical: true))
      refute Predicate.eval({:is_critical_hit}, with_resolution(ctx(), is_critical: false))
    end

    test "{:is_bonus_action_attack}" do
      assert Predicate.eval(
               {:is_bonus_action_attack},
               with_resolution(ctx(), economy_slot: :bonus_action)
             )

      refute Predicate.eval(
               {:is_bonus_action_attack},
               with_resolution(ctx(), economy_slot: :action)
             )
    end

    test "{:damage_type_is, type}" do
      assert Predicate.eval({:damage_type_is, :fire}, with_resolution(ctx(), damage_type: :fire))
      refute Predicate.eval({:damage_type_is, :cold}, with_resolution(ctx(), damage_type: :fire))
    end
  end

  # ---------------------------------------------------------------------------
  # Group 7 — Turn History
  # ---------------------------------------------------------------------------

  describe "Group 7 — turn history" do
    test "all Group 7 predicates return true outside :in_combat" do
      preds = [
        {:first_attack_this_turn},
        {:has_moved_this_turn},
        {:has_used_action_this_turn},
        {:has_used_bonus_action_this_turn},
        {:took_damage_this_turn},
        {:took_damage_type_this_turn, :fire},
        {:entity_was_attacked_this_round},
        {:round_number_gte, 999}
      ]

      c = with_scene(ctx(), phase: :exploration)

      for pred <- preds do
        assert Predicate.eval(pred, c), "expected #{inspect(pred)} to be true outside :in_combat"
      end
    end

    test "{:first_attack_this_turn} true when no attack in log" do
      assert Predicate.eval({:first_attack_this_turn}, ctx())
    end

    test "{:first_attack_this_turn} false after attack logged" do
      c = with_scene(ctx(), event_log: [%{type: :attack_rolled, actor_id: 1, turn: 1}])
      refute Predicate.eval({:first_attack_this_turn}, c)
    end

    test "{:round_number_gte, n} in :in_combat" do
      assert Predicate.eval({:round_number_gte, 1}, with_scene(ctx(), current_round: 2))
      refute Predicate.eval({:round_number_gte, 5}, with_scene(ctx(), current_round: 2))
    end

    test "{:took_damage_this_turn} false when no damage in log" do
      refute Predicate.eval({:took_damage_this_turn}, ctx())
    end

    test "{:took_damage_this_turn} true when damage event exists" do
      c = with_scene(ctx(), event_log: [%{type: :damage_received, target_id: 1, turn: 1}])
      assert Predicate.eval({:took_damage_this_turn}, c)
    end
  end

  # ---------------------------------------------------------------------------
  # Group 8 — Scene State
  # ---------------------------------------------------------------------------

  describe "Group 8 — scene state" do
    test "{:scene_phase_is, phase}" do
      assert Predicate.eval({:scene_phase_is, :in_combat}, ctx())
      refute Predicate.eval({:scene_phase_is, :exploration}, ctx())
    end

    test "{:entity_has_active_effect, key}" do
      c = with_scene(ctx(), active_effects: [%{entity_id: 1, key: :bless}])
      assert Predicate.eval({:entity_has_active_effect, :bless}, c)
      refute Predicate.eval({:entity_has_active_effect, :hex}, c)
    end

    test "{:effect_source_is, source}" do
      c = with_scene(ctx(), current_effect_source: :spell)
      assert Predicate.eval({:effect_source_is, :spell}, c)
      refute Predicate.eval({:effect_source_is, :item}, c)
    end
  end
end
