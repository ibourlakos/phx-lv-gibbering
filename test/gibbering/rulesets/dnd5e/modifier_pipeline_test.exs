defmodule Gibbering.Rulesets.DnD5e.ModifierPipelineTest do
  use ExUnit.Case, async: true

  alias Gibbering.Rulesets.DnD5e.{ModifierPipeline, RuleModifier}

  defp modifier(overrides) do
    defaults = %{
      id: :test,
      name: "Test",
      trigger: :passive,
      predicate: {:always},
      effect: {:add_bonus, :damage, 1},
      stacking: :additive,
      min_level: 1
    }

    struct(RuleModifier, Map.merge(defaults, Map.new(overrides)))
  end

  defp entity(overrides) do
    Map.merge(
      %{id: 1, class: "fighter", race: "human", level: 1, conditions: []},
      Map.new(overrides)
    )
  end

  defp eval_ctx(entity_map) do
    %{
      entity: entity_map,
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
  end

  # ---------------------------------------------------------------------------
  # collect_modifiers/3
  # ---------------------------------------------------------------------------

  describe "collect_modifiers/3" do
    test "returns only condition modifiers for an entity with no matching class/race" do
      e = entity(class: "fighter")
      result = ModifierPipeline.collect_modifiers(e, {:on_attack, :melee}, eval_ctx(e))
      # fighter melee attack — no condition mods on this entity
      assert is_list(result)
      refute Enum.any?(result, &(&1.id == :rogue_sneak_attack))
    end

    test "filters by min_level" do
      e = entity(class: "rogue", level: 1)
      result = ModifierPipeline.collect_modifiers(e, {:on_attack, :any}, eval_ctx(e))
      assert is_list(result)
    end

    test "poisoned entity gets attack disadvantage modifier" do
      e = entity(conditions: [:poisoned])
      ctx = eval_ctx(e)
      result = ModifierPipeline.collect_modifiers(e, {:on_attack, :any}, ctx)
      assert Enum.any?(result, &(&1.id == :poisoned_dis_attacks))
    end

    test "attacking a blinded target yields advantage modifier" do
      attacker = entity(conditions: [])
      target = entity(id: 2, conditions: [:blinded])
      ctx = %{eval_ctx(attacker) | target: target}
      result = ModifierPipeline.collect_modifiers(attacker, {:on_attack, :any}, ctx)
      assert Enum.any?(result, &(&1.id == :blinded_adv_against))
      refute Enum.any?(result, &(&1.id == :blinded_dis_attacks))
    end

    test "uniq_by id prevents double modifiers when both combatants share a condition" do
      # Both entity and target are blinded: each has one blinded condition.
      # After uniq_by, :blinded_dis_attacks and :blinded_adv_against appear
      # exactly once each in the collected list.
      attacker = entity(conditions: [:blinded])
      target = entity(id: 2, conditions: [:blinded])

      scene = %{
        entities: %{1 => attacker, 2 => target},
        grid: %{},
        active_effects: [],
        event_log: [],
        phase: :in_combat,
        current_turn: 1,
        current_round: 1
      }

      ctx = %{entity: attacker, target: target, scene: scene, resolution: nil}
      result = ModifierPipeline.collect_modifiers(attacker, {:on_attack, :any}, ctx)

      dis_count = Enum.count(result, &(&1.id == :blinded_dis_attacks))
      adv_count = Enum.count(result, &(&1.id == :blinded_adv_against))
      assert dis_count == 1
      assert adv_count == 1
    end
  end

  describe "collect_modifiers/3 — class features" do
    test "fighter gets :fighter_second_wind modifier on :on_second_wind trigger" do
      e = entity(class: "fighter", resources: %{second_wind: 1})
      result = ModifierPipeline.collect_modifiers(e, :on_second_wind, eval_ctx(e))
      assert Enum.any?(result, &(&1.id == :fighter_second_wind))
    end

    test "rogue with ally adjacent to target gets :rogue_sneak_attack on attack" do
      rogue = entity(id: 1, class: "rogue", type: "hero", x: 0, y: 0)
      target = entity(id: 2, type: "monster", x: 1, y: 0)
      ally = entity(id: 3, type: "hero", x: 2, y: 0)

      scene = %{
        entities: %{1 => rogue, 2 => target, 3 => ally},
        grid: %{},
        active_effects: [],
        event_log: [],
        phase: :in_combat,
        current_turn: 1,
        current_round: 1
      }

      ctx = %{entity: rogue, target: target, scene: scene, resolution: nil}
      result = ModifierPipeline.collect_modifiers(rogue, {:on_attack, :any}, ctx)
      assert Enum.any?(result, &(&1.id == :rogue_sneak_attack))
    end

    test "barbarian in rage gets :barbarian_rage_damage on melee attack" do
      barb = entity(id: 1, class: "barbarian", conditions: [:raging])
      target = entity(id: 2, type: "monster", x: 1, y: 0)

      ctx = %{
        entity: barb,
        target: target,
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

      result = ModifierPipeline.collect_modifiers(barb, {:on_attack, :melee}, ctx)
      assert Enum.any?(result, &(&1.id == :barbarian_rage_damage))
    end
  end

  describe "collect_modifiers/3 — race traits" do
    test "elf gets :elf_darkvision modifier (passive — included on any trigger)" do
      e = entity(race: "elf")
      result = ModifierPipeline.collect_modifiers(e, {:on_attack, :any}, eval_ctx(e))
      assert Enum.any?(result, &(&1.id == :elf_darkvision))
    end

    test "gnome gets :gnome_cunning modifier on intelligence saving throw" do
      gnome = entity(id: 1, race: "gnome")

      ctx = %{
        eval_ctx(gnome)
        | resolution: %{saving_throw_ability: :intelligence}
      }

      result = ModifierPipeline.collect_modifiers(gnome, {:on_saving_throw, :any}, ctx)
      assert Enum.any?(result, &(&1.id == :gnome_cunning))
    end
  end

  # ---------------------------------------------------------------------------
  # apply_modifiers/2 — stacking rules
  # ---------------------------------------------------------------------------

  describe "apply_modifiers/2 — stacking: :additive" do
    test "sums all additive bonuses of the same type" do
      mods = [
        modifier(id: :bonus_a, effect: {:add_bonus, :damage, 2}, stacking: :additive),
        modifier(id: :bonus_b, effect: {:add_bonus, :damage, 3}, stacking: :additive)
      ]

      result = ModifierPipeline.apply_modifiers(%{}, mods)
      assert result.damage_total == 5
    end

    test "stacks additive attack and damage bonuses independently" do
      mods = [
        modifier(id: :a, effect: {:add_bonus, :attack, 2}, stacking: :additive),
        modifier(id: :b, effect: {:add_bonus, :damage, 1}, stacking: :additive)
      ]

      result = ModifierPipeline.apply_modifiers(%{}, mods)
      assert result.attack_bonus == 2
      assert result.damage_total == 1
    end
  end

  describe "apply_modifiers/2 — stacking: :named_bonus" do
    test "only the highest modifier of the same id applies" do
      mods = [
        modifier(id: :bless, effect: {:add_bonus, :attack, 3}, stacking: :named_bonus),
        modifier(id: :bless, effect: {:add_bonus, :attack, 5}, stacking: :named_bonus)
      ]

      result = ModifierPipeline.apply_modifiers(%{}, mods)
      assert result.attack_bonus == 5
    end

    test "two different named_bonus ids each contribute their highest" do
      mods = [
        modifier(id: :bless, effect: {:add_bonus, :attack, 3}, stacking: :named_bonus),
        modifier(id: :bless, effect: {:add_bonus, :attack, 1}, stacking: :named_bonus),
        modifier(id: :heroism, effect: {:add_bonus, :attack, 4}, stacking: :named_bonus)
      ]

      result = ModifierPipeline.apply_modifiers(%{}, mods)
      assert result.attack_bonus == 7
    end
  end

  describe "apply_modifiers/2 — stacking: :binary_flag" do
    test "advantage accumulates a count" do
      mods = [
        modifier(id: :adv1, effect: {:grant_advantage, :attack_rolls}, stacking: :binary_flag),
        modifier(id: :adv2, effect: {:grant_advantage, :attack_rolls}, stacking: :binary_flag)
      ]

      result = ModifierPipeline.apply_modifiers(%{}, mods)
      assert result.advantage_count == 2
    end

    test "resistance sets damage_multiplier to 0.5" do
      mods = [
        modifier(id: :rage_res, effect: {:grant_resistance, :slashing}, stacking: :binary_flag)
      ]

      result = ModifierPipeline.apply_modifiers(%{}, mods)
      assert result.damage_multiplier == 0.5
    end

    test "immunity overrides resistance and sets multiplier to 0" do
      mods = [
        modifier(id: :res, effect: {:grant_resistance, :fire}, stacking: :binary_flag),
        modifier(id: :imm, effect: {:grant_immunity, :fire}, stacking: :binary_flag)
      ]

      result = ModifierPipeline.apply_modifiers(%{}, mods)
      assert result.damage_multiplier == 0
    end
  end

  # ---------------------------------------------------------------------------
  # apply_modifiers/2 — effect layers
  # ---------------------------------------------------------------------------

  describe "apply_modifiers/2 — layering order" do
    test "force_critical_hit sets is_critical" do
      mods = [modifier(id: :auto_crit, effect: {:force_critical_hit}, stacking: :binary_flag)]
      result = ModifierPipeline.apply_modifiers(%{}, mods)
      assert result.is_critical == true
    end

    test "add_damage_dice accumulates dice strings" do
      mods = [
        modifier(
          id: :sneak,
          effect: {:add_damage_dice, "1d6", :sneak_attack},
          stacking: :named_bonus
        ),
        modifier(
          id: :smite,
          effect: {:add_damage_dice, "2d8", :divine_smite},
          stacking: :additive
        )
      ]

      result = ModifierPipeline.apply_modifiers(%{}, mods)
      assert "1d6" in result.damage_dice
      assert "2d8" in result.damage_dice
    end

    test "add_to_roll accumulates roll dice" do
      mods = [modifier(id: :bless_roll, effect: {:add_to_roll, "1d4"}, stacking: :named_bonus)]
      result = ModifierPipeline.apply_modifiers(%{}, mods)
      assert "1d4" in result.roll_dice
    end

    test "disadvantage accumulates a count" do
      mods = [
        modifier(id: :dis1, effect: {:impose_disadvantage, :attack_rolls}, stacking: :binary_flag)
      ]

      result = ModifierPipeline.apply_modifiers(%{}, mods)
      assert result.disadvantage_count == 1
    end

    test "empty modifier list returns context unchanged" do
      ctx = %{damage_total: 5}
      assert ModifierPipeline.apply_modifiers(ctx, []) == ctx
    end
  end
end
