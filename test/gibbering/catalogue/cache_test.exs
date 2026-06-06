defmodule Gibbering.Catalogue.CacheTest do
  # async: false + DataCase: ETS tables are global, and reload!/0 queries the DB from
  # the Cache GenServer's process. DataCase's shared sandbox lets that process use the
  # test connection without an explicit allow call.
  use Gibbering.DataCase, async: false

  alias Gibbering.Catalogue.Cache
  alias Gibbering.Data.{Races, Classes, Spells}

  describe "list_races/0" do
    test "returns all seeded races" do
      results = Cache.list_races()
      keys = Enum.map(results, & &1.key) |> Enum.sort()
      assert keys == Map.keys(Races.seed_data()) |> Enum.sort()
    end

    test "returns structs with expected fields" do
      [race | _] = Cache.list_races()
      assert race.key
      assert race.name
      assert race.speed
    end
  end

  describe "list_classes/0" do
    test "returns all seeded classes" do
      results = Cache.list_classes()
      keys = Enum.map(results, & &1.key) |> Enum.sort()
      assert keys == Map.keys(Classes.seed_data()) |> Enum.sort()
    end
  end

  describe "list_spells/0" do
    test "returns all seeded spells" do
      results = Cache.list_spells()
      assert length(results) == map_size(Spells.seed_data())
    end

    test "returns structs with expected fields" do
      [spell | _] = Cache.list_spells()
      assert spell.key
      assert spell.name
      assert is_integer(spell.level)
    end
  end

  describe "get_race/1" do
    test "returns race struct for known key" do
      race = Cache.get_race("elf")
      assert race.key == "elf"
      assert race.name
    end

    test "returns nil for unknown key" do
      assert Cache.get_race("orc") == nil
    end
  end

  describe "get_class/1" do
    test "returns class struct for known key" do
      cls = Cache.get_class("wizard")
      assert cls.key == "wizard"
      assert cls.name
    end

    test "returns nil for unknown key" do
      assert Cache.get_class("paladin") == nil
    end
  end

  describe "get_spell/1" do
    test "returns spell struct for known key" do
      spell = Cache.get_spell("fire_bolt")
      assert spell.key == "fire_bolt"
      assert spell.name
    end

    test "returns nil for unknown key" do
      assert Cache.get_spell("wish") == nil
    end
  end

  describe "reload!/0" do
    test "returns :ok and data remains accessible after reload" do
      assert Cache.reload!() == :ok
      assert length(Cache.list_races()) == map_size(Races.seed_data())
      assert length(Cache.list_classes()) == map_size(Classes.seed_data())
    end
  end
end
