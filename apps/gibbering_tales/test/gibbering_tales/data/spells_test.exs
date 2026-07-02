defmodule GibberingTales.Data.SpellsTest do
  use ExUnit.Case, async: true

  alias GibberingTales.Data.Spells
  alias GibberingTales.Rulesets.DnD5e.Spell

  @all_keys ~w(fire_bolt mage_hand minor_illusion sacred_flame magic_missile
               cure_wounds burning_hands sleep thunderwave)

  describe "seed_data/0" do
    test "returns a map with exactly 9 SRD spells" do
      data = Spells.seed_data()
      assert map_size(data) == 9

      for key <- @all_keys do
        assert Map.has_key?(data, key), "Missing spell: #{key}"
      end
    end

    test "every spell has all required fields" do
      for {_key, spell} <- Spells.seed_data() do
        assert is_binary(spell.name)
        assert is_integer(spell.level) and spell.level >= 0
        assert is_binary(spell.school)
        assert is_binary(spell.casting_time)
        assert is_binary(spell.range)
        assert is_binary(spell.description)
        assert is_binary(spell.attack_type)
        assert is_list(spell.tags)
      end
    end

    test "cantrips have level 0" do
      data = Spells.seed_data()
      assert data["fire_bolt"].level == 0
      assert data["mage_hand"].level == 0
      assert data["minor_illusion"].level == 0
      assert data["sacred_flame"].level == 0
    end

    test "magic_missile is a level 1 spell" do
      assert Spells.seed_data()["magic_missile"].level == 1
    end

    test "damage-dealing spells have damage_dice and damage_type" do
      for {_key, spell} <- Spells.seed_data(), spell.attack_type != "utility" do
        assert is_binary(spell.damage_dice) or is_nil(spell.damage_dice)
      end
    end

    test "save spells have a save ability" do
      for {_key, spell} <- Spells.seed_data(), spell.attack_type == "save" do
        assert is_binary(spell.save),
               "#{spell.name} has attack_type 'save' but no save ability"
      end
    end
  end

  describe "all/0" do
    test "returns exactly 9 %Spell{} structs" do
      all = Spells.all()
      assert map_size(all) == 9
      for {_key, spell} <- all, do: assert(%Spell{} = spell)
    end

    test "all keys are atoms" do
      for key <- Map.keys(Spells.all()), do: assert(is_atom(key))
    end

    test "each spell key matches its struct :key field" do
      for {key, spell} <- Spells.all(), do: assert(spell.key == key)
    end

    test "fire_bolt has correct struct fields" do
      spell = Spells.all().fire_bolt
      assert spell.level == 0
      assert spell.school == :evocation
      assert spell.casting_time == {:action}
      assert spell.range == {:feet, 120}
      assert spell.target_area.shape == :point
      assert spell.effect.attack_type == :ranged_attack
      assert spell.effect.damage_dice == "1d10"
      assert spell.effect.damage_type == :fire
      assert spell.duration.is_concentration == false
    end

    test "magic_missile uses :auto attack_type with flat damage dice" do
      spell = Spells.all().magic_missile
      assert spell.level == 1
      assert spell.effect.attack_type == :auto
      assert spell.effect.damage_dice == "1d4+1"
    end

    test "cure_wounds has :touch range and shape" do
      spell = Spells.all().cure_wounds
      assert spell.range == :touch
      assert spell.target_area.shape == :touch
    end

    test "burning_hands has :cone target area from :self range" do
      spell = Spells.all().burning_hands
      assert spell.range == :self
      assert spell.target_area.shape == :cone
      assert spell.target_area.size == 15
    end

    test "sleep has :sphere target area and 1-minute duration" do
      spell = Spells.all().sleep
      assert spell.target_area.shape == :sphere
      assert spell.target_area.size == 20
      assert spell.duration.value == "1 minute"
    end

    test "thunderwave has :cube target area and :constitution save" do
      spell = Spells.all().thunderwave
      assert spell.target_area.shape == :cube
      assert spell.target_area.size == 15
      assert spell.effect.save == :constitution
    end

    test "mage_hand is utility with 1-minute non-concentration duration" do
      spell = Spells.all().mage_hand
      assert spell.effect.attack_type == :utility
      assert spell.duration.value == "1 minute"
      assert spell.duration.is_concentration == false
    end
  end

  describe "get/1 — atom key" do
    test "returns the %Spell{} for a known key" do
      assert %Spell{key: :fire_bolt} = Spells.get(:fire_bolt)
    end

    test "returns nil for an unknown atom key" do
      assert Spells.get(:unknown_spell) == nil
    end
  end

  describe "get/1 — string key" do
    test "returns the %Spell{} for a known string key" do
      assert %Spell{key: :fire_bolt} = Spells.get("fire_bolt")
    end

    test "returns nil for an unknown string key" do
      assert Spells.get("not_a_spell") == nil
    end
  end
end
