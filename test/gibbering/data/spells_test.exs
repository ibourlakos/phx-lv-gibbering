defmodule Gibbering.Data.SpellsTest do
  use ExUnit.Case, async: true

  alias Gibbering.Data.Spells

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
end
