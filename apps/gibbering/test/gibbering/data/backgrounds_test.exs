defmodule Gibbering.Data.BackgroundsTest do
  use ExUnit.Case, async: true

  alias Gibbering.Data.Backgrounds

  @all_keys ~w(acolyte charlatan criminal entertainer folk_hero guild_artisan
               hermit noble outlander sage sailor soldier urchin)

  describe "get/1" do
    test "returns a background map for a known key" do
      bg = Backgrounds.get("acolyte")
      assert bg.name == "Acolyte"
      assert bg.skill_proficiencies == ["insight", "religion"]
      assert is_list(bg.tool_proficiencies)
      assert bg.languages == 2
      assert is_list(bg.starting_equipment)
      assert is_map(bg.feature)
      assert is_binary(bg.feature.name)
    end

    test "returns nil for an unknown key" do
      assert Backgrounds.get("dragon_disciple") == nil
    end
  end

  describe "all/0" do
    test "returns a map with exactly 13 SRD backgrounds" do
      all = Backgrounds.all()
      assert map_size(all) == 13

      for key <- @all_keys do
        assert Map.has_key?(all, key), "Missing background: #{key}"
      end
    end

    test "every background has all required fields" do
      for {_key, bg} <- Backgrounds.all() do
        assert is_binary(bg.name)
        assert is_binary(bg.description)
        assert is_list(bg.skill_proficiencies)
        assert length(bg.skill_proficiencies) == 2
        assert is_list(bg.tool_proficiencies)
        assert is_integer(bg.languages) and bg.languages >= 0
        assert is_list(bg.starting_equipment)
        assert is_map(bg.feature)
        assert is_binary(bg.feature.name)
        assert is_binary(bg.feature.description)
        assert is_list(bg.suggested_traits) and length(bg.suggested_traits) >= 2
        assert is_list(bg.suggested_ideals) and length(bg.suggested_ideals) >= 2
        assert is_list(bg.suggested_bonds) and length(bg.suggested_bonds) >= 2
        assert is_list(bg.suggested_flaws) and length(bg.suggested_flaws) >= 2
      end
    end
  end

  describe "keys/0" do
    test "returns the list of all 13 background keys" do
      assert Enum.sort(Backgrounds.keys()) == Enum.sort(@all_keys)
    end
  end
end
