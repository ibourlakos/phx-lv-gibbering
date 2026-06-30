defmodule Gibbering.Data.ItemsTest do
  use ExUnit.Case, async: true

  alias Gibbering.Data.Items

  @weapon_keys ~w(dagger handaxe javelin quarterstaff light_crossbow
                  battleaxe greatsword longsword rapier scimitar shortsword)
  @armor_keys ~w(padded_armor leather_armor chain_shirt scale_mail
                 chain_mail plate_armor shield)
  @consumable_keys ~w(healing_potion greater_healing_potion)

  describe "all/0" do
    test "returns all 20 items" do
      all = Items.all()
      assert map_size(all) == 20
    end

    test "all weapon keys present" do
      all = Items.all()
      for key <- @weapon_keys, do: assert(Map.has_key?(all, key), "Missing weapon: #{key}")
    end

    test "all armor keys present" do
      all = Items.all()
      for key <- @armor_keys, do: assert(Map.has_key?(all, key), "Missing armor: #{key}")
    end

    test "all consumable keys present" do
      all = Items.all()

      for key <- @consumable_keys,
          do: assert(Map.has_key?(all, key), "Missing consumable: #{key}")
    end

    test "every item has shared fields" do
      for {_key, item} <- Items.all() do
        assert is_binary(item.name)
        assert item.item_type in [:weapon, :armor, :consumable]
        assert is_number(item.weight_pounds)
        assert is_number(item.cost_gp)
        assert is_boolean(item.is_magical)
        assert is_boolean(item.requires_attunement)
      end
    end
  end

  describe "all/0 — weapons" do
    test "every weapon has damage_dice, damage_type, weapon_category, and weapon_properties" do
      weapons = Items.all() |> Map.filter(fn {_, v} -> v.item_type == :weapon end)

      for {_key, item} <- weapons do
        assert is_binary(item.damage_dice), "#{item.name} missing damage_dice"
        assert is_binary(item.damage_type), "#{item.name} missing damage_type"
        assert item.weapon_category in [:simple, :martial], "#{item.name} bad weapon_category"
        assert is_list(item.weapon_properties), "#{item.name} missing weapon_properties"
      end
    end

    test "simple weapons: dagger, handaxe, quarterstaff, javelin, light_crossbow" do
      for key <- ~w(dagger handaxe quarterstaff javelin light_crossbow) do
        assert Items.get(key).weapon_category == :simple
      end
    end

    test "martial weapons: battleaxe, greatsword, longsword, rapier, scimitar, shortsword" do
      for key <- ~w(battleaxe greatsword longsword rapier scimitar shortsword) do
        assert Items.get(key).weapon_category == :martial
      end
    end

    test "greatsword has 2d6 damage" do
      assert Items.get("greatsword").damage_dice == "2d6"
    end

    test "dagger has finesse property" do
      assert "finesse" in Items.get("dagger").weapon_properties
    end
  end

  describe "all/0 — armor" do
    test "every armor item has base_ac, armor_category, stealth_disadvantage, strength_requirement" do
      armors = Items.all() |> Map.filter(fn {_, v} -> v.item_type == :armor end)

      for {_key, item} <- armors do
        assert is_integer(item.base_ac), "#{item.name} missing base_ac"

        assert item.armor_category in [:light, :medium, :heavy, :shield],
               "#{item.name} bad armor_category"

        assert is_boolean(item.stealth_disadvantage), "#{item.name} missing stealth_disadvantage"
      end
    end

    test "plate_armor has AC 18 and strength requirement 15" do
      plate = Items.get("plate_armor")
      assert plate.base_ac == 18
      assert plate.strength_requirement == 15
    end

    test "chain_mail requires strength 13" do
      assert Items.get("chain_mail").strength_requirement == 13
    end

    test "shield is armor_category :shield with AC 2" do
      shield = Items.get("shield")
      assert shield.armor_category == :shield
      assert shield.base_ac == 2
    end

    test "leather_armor has no stealth disadvantage" do
      refute Items.get("leather_armor").stealth_disadvantage
    end

    test "scale_mail imposes stealth disadvantage" do
      assert Items.get("scale_mail").stealth_disadvantage
    end
  end

  describe "all/0 — consumables" do
    test "every consumable has charges and effect_description" do
      consumables = Items.all() |> Map.filter(fn {_, v} -> v.item_type == :consumable end)

      for {_key, item} <- consumables do
        assert is_integer(item.charges), "#{item.name} missing charges"
        assert is_binary(item.effect_description), "#{item.name} missing effect_description"
      end
    end

    test "healing potions are magical" do
      assert Items.get("healing_potion").is_magical
      assert Items.get("greater_healing_potion").is_magical
    end
  end

  describe "all/0 — modifiers (issue #128)" do
    alias Gibbering.Engine.RuleModifier

    test "every item carries a modifiers list" do
      for {key, item} <- Items.all() do
        assert is_list(item.modifiers), "#{key} missing modifiers list"

        assert Enum.all?(item.modifiers, &match?(%RuleModifier{}, &1)),
               "#{key} modifiers must be %RuleModifier{} structs"
      end
    end

    test "finesse weapons grant a DEX-or-STR attack ability choice" do
      for key <- ~w(dagger rapier scimitar shortsword) do
        mods = Items.get(key).modifiers

        assert Enum.any?(mods, fn m ->
                 m.effect == {:choose_attack_ability, [:dexterity, :strength]} and
                   match?({:on_attack, _}, m.trigger)
               end),
               "#{key} should carry a finesse attack-ability-choice modifier"
      end
    end

    test "non-finesse weapons have no modifiers" do
      for key <- ~w(handaxe javelin quarterstaff light_crossbow battleaxe greatsword longsword) do
        assert Items.get(key).modifiers == [], "#{key} should have no modifiers"
      end
    end

    test "shield grants an additive +2 AC bonus" do
      mods = Items.get("shield").modifiers

      assert Enum.any?(mods, fn m ->
               m.effect == {:add_bonus, :ac, 2} and m.trigger == :passive and
                 m.stacking == :additive
             end)
    end

    test "body armor carries an override_ac_formula modifier matching its category and base AC" do
      for {key, category, base_ac} <- [
            {"padded_armor", :light, 11},
            {"leather_armor", :light, 11},
            {"chain_shirt", :medium, 13},
            {"scale_mail", :medium, 14},
            {"chain_mail", :heavy, 16},
            {"plate_armor", :heavy, 18}
          ] do
        mods = Items.get(key).modifiers

        assert Enum.any?(mods, fn m ->
                 m.effect == {:override_ac_formula, {:armor, category, base_ac}} and
                   m.trigger == :passive
               end),
               "#{key} should carry an override_ac_formula modifier"
      end
    end

    test "consumables have no modifiers" do
      assert Items.get("healing_potion").modifiers == []
      assert Items.get("greater_healing_potion").modifiers == []
    end
  end

  describe "get/1" do
    test "returns item for a known key" do
      item = Items.get("longsword")
      assert item.name == "Longsword"
      assert item.item_type == :weapon
    end

    test "returns nil for an unknown key" do
      assert Items.get("vorpal_blade") == nil
    end
  end
end
