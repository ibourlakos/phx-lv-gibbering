defmodule Gibbering.Data.ClassesTest do
  use ExUnit.Case, async: true

  alias Gibbering.Data.Classes

  @all_keys ~w(barbarian bard cleric druid fighter monk paladin ranger rogue sorcerer warlock wizard)

  describe "seed_data/0" do
    test "returns all standard SRD classes" do
      data = Classes.seed_data()
      assert map_size(data) == length(@all_keys)

      for key <- @all_keys do
        assert Map.has_key?(data, key), "Missing class: #{key}"
      end
    end

    test "every class has all required fields" do
      for {_key, cls} <- Classes.seed_data() do
        assert is_binary(cls.name)
        assert is_binary(cls.description)
        assert is_binary(cls.hit_die)
        assert is_integer(cls.base_hp) and cls.base_hp > 0
        assert is_list(cls.primary_stats) and length(cls.primary_stats) >= 1
        assert is_list(cls.saving_throws) and length(cls.saving_throws) == 2
        assert is_list(cls.armor_proficiencies)
        assert is_list(cls.weapon_proficiencies)
        assert is_boolean(cls.spellcasting)
        assert is_list(cls.spells)
        assert is_list(cls.features) and length(cls.features) >= 1
        assert is_map(cls.stats)
      end
    end

    test "fighter is non-spellcasting with d10 hit die" do
      cls = Classes.seed_data()["fighter"]
      assert cls.hit_die == "d10"
      assert cls.spellcasting == false
    end

    test "wizard is spellcasting with d6 hit die" do
      cls = Classes.seed_data()["wizard"]
      assert cls.hit_die == "d6"
      assert cls.spellcasting == true
    end

    test "each feature has name and description" do
      for {_key, cls} <- Classes.seed_data() do
        for feature <- cls.features do
          assert is_binary(feature.name)
          assert is_binary(feature.description)
        end
      end
    end
  end
end
