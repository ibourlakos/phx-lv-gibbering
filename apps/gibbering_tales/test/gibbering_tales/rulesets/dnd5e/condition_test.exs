defmodule GibberingTales.Rulesets.DnD5e.ConditionTest do
  use ExUnit.Case, async: true

  alias GibberingEngine.RuleModifier
  alias GibberingTales.Rulesets.DnD5e.Condition

  @all_ids [
    :blinded,
    :charmed,
    :deafened,
    :exhaustion,
    :frightened,
    :grappled,
    :incapacitated,
    :invisible,
    :paralyzed,
    :petrified,
    :poisoned,
    :prone,
    :restrained,
    :stunned
  ]

  describe "all/0" do
    test "returns all 14 SRD conditions plus movement-granting conditions" do
      assert map_size(Condition.all()) >= 14
    end

    test "contains every expected condition id" do
      for id <- @all_ids do
        assert Map.has_key?(Condition.all(), id), "missing condition: #{id}"
      end
    end

    test "every condition has a non-empty name" do
      for {_id, cond} <- Condition.all() do
        assert is_binary(cond.name) and cond.name != ""
      end
    end
  end

  describe "get/1" do
    test "returns the condition struct for a known id" do
      assert %Condition{id: :poisoned, name: "Poisoned"} = Condition.get(:poisoned)
    end

    test "returns nil for an unknown id" do
      assert Condition.get(:not_a_condition) == nil
    end
  end

  describe "blinded" do
    test "has two modifiers" do
      assert length(Condition.get(:blinded).modifiers) == 2
    end

    test "attacker disadvantage fires on entity_has_condition :blinded" do
      mod = Enum.find(Condition.get(:blinded).modifiers, &(&1.id == :blinded_dis_attacks))
      assert mod.predicate == {:entity_has_condition, :blinded}
      assert mod.effect == {:impose_disadvantage, :attack_rolls}
    end

    test "advantage against fires on target_has_condition :blinded" do
      mod = Enum.find(Condition.get(:blinded).modifiers, &(&1.id == :blinded_adv_against))
      assert mod.predicate == {:target_has_condition, :blinded}
      assert mod.effect == {:grant_advantage, :attack_rolls}
    end
  end

  describe "poisoned" do
    test "has one modifier: attack disadvantage on entity_has_condition :poisoned" do
      [mod] = Condition.get(:poisoned).modifiers
      assert mod.id == :poisoned_dis_attacks
      assert mod.predicate == {:entity_has_condition, :poisoned}
      assert mod.effect == {:impose_disadvantage, :attack_rolls}
    end
  end

  describe "incapacitated" do
    test "has no roll modifiers (enforced at action-economy layer)" do
      assert Condition.get(:incapacitated).modifiers == []
    end
  end

  describe "grappled" do
    test "has set_all_speeds 0 modifier" do
      [mod] = Condition.get(:grappled).modifiers
      assert mod.effect == {:set_all_speeds, 0}
      assert mod.predicate == {:entity_has_condition, :grappled}
    end
  end

  describe "paralyzed" do
    test "has advantage-against and adjacent auto-crit modifiers" do
      mods = Condition.get(:paralyzed).modifiers
      ids = Enum.map(mods, & &1.id)
      assert :paralyzed_adv_against in ids
      assert :paralyzed_auto_crit in ids
    end

    test "auto-crit predicate requires adjacency" do
      crit = Enum.find(Condition.get(:paralyzed).modifiers, &(&1.id == :paralyzed_auto_crit))
      assert {:all_of, preds} = crit.predicate
      assert {:entity_adjacent_to_target} in preds
    end
  end

  describe "prone" do
    test "has three modifiers covering self, melee-attacker, and ranged-attacker" do
      mods = Condition.get(:prone).modifiers
      assert length(mods) == 3

      ids = Enum.map(mods, & &1.id) |> MapSet.new()
      assert MapSet.member?(ids, :prone_dis_attacks)
      assert MapSet.member?(ids, :prone_adv_melee)
      assert MapSet.member?(ids, :prone_dis_ranged)
    end

    test "melee trigger targets {:on_attack, :melee}" do
      mod = Enum.find(Condition.get(:prone).modifiers, &(&1.id == :prone_adv_melee))
      assert mod.trigger == {:on_attack, :melee}
    end

    test "ranged trigger targets {:on_attack, :ranged}" do
      mod = Enum.find(Condition.get(:prone).modifiers, &(&1.id == :prone_dis_ranged))
      assert mod.trigger == {:on_attack, :ranged}
    end
  end

  describe "restrained" do
    test "has speed-0, attack-dis, attacker-adv, and dex-save-dis modifiers" do
      ids = Condition.get(:restrained).modifiers |> Enum.map(& &1.id) |> MapSet.new()
      assert MapSet.member?(ids, :restrained_no_speed)
      assert MapSet.member?(ids, :restrained_dis_attacks)
      assert MapSet.member?(ids, :restrained_adv_against)
      assert MapSet.member?(ids, :restrained_dis_dex_saves)
    end
  end

  describe "all modifiers are valid %RuleModifier{} structs" do
    test "every modifier has required fields" do
      for {_id, cond} <- Condition.all(), mod <- cond.modifiers do
        assert %RuleModifier{id: id, name: name, trigger: t, predicate: p, effect: e} = mod
        assert id != nil
        assert is_binary(name) and name != ""
        assert t != nil
        assert p != nil
        assert e != nil
      end
    end
  end
end
