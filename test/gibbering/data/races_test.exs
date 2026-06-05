defmodule Gibbering.Data.RacesTest do
  use ExUnit.Case, async: true

  alias Gibbering.Data.Races

  @all_keys ~w(human elf gnome)

  describe "seed_data/0" do
    test "returns a map with exactly 3 SRD races" do
      data = Races.seed_data()
      assert map_size(data) == 3

      for key <- @all_keys do
        assert Map.has_key?(data, key), "Missing race: #{key}"
      end
    end

    test "every race has all required fields" do
      for {_key, race} <- Races.seed_data() do
        assert is_binary(race.name)
        assert is_binary(race.description)
        assert is_integer(race.speed) and race.speed > 0
        assert is_map(race.stat_bonuses)
        assert is_list(race.traits)
        assert is_boolean(race.darkvision)
      end
    end

    test "each trait has name and description" do
      for {_key, race} <- Races.seed_data() do
        for trait <- race.traits do
          assert is_binary(trait.name)
          assert is_binary(trait.description)
        end
      end
    end

    test "human has no darkvision and speed 30" do
      race = Races.seed_data()["human"]
      assert race.darkvision == false
      assert race.speed == 30
    end

    test "elf and gnome have darkvision" do
      data = Races.seed_data()
      assert data["elf"].darkvision == true
      assert data["gnome"].darkvision == true
    end

    test "gnome has slower movement speed than human and elf" do
      data = Races.seed_data()
      assert data["gnome"].speed == 25
      assert data["human"].speed == 30
      assert data["elf"].speed == 30
    end
  end
end
