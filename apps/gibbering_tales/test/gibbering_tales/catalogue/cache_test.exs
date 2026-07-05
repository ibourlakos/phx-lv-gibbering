defmodule GibberingTales.Catalogue.CacheTest do
  # async: false + DataCase: ETS tables are global, and reload!/0 queries the DB from
  # the Cache GenServer's process. DataCase's shared sandbox lets that process use the
  # test connection without an explicit allow call.
  use GibberingTales.DataCase, async: false

  alias GibberingTales.Catalogue.Cache
  alias GibberingTales.Catalogue.{Race, Class}
  alias GibberingTales.Data.Spells

  describe "list_races/0" do
    test "returns all seeded races" do
      # Cache reflects the test DB. Compare against actual DB row count.
      db_count = Repo.aggregate(Race, :count)
      assert length(Cache.list_races()) == db_count
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
      db_count = Repo.aggregate(Class, :count)
      assert length(Cache.list_classes()) == db_count
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
      assert length(Cache.list_races()) == Repo.aggregate(Race, :count)
      assert length(Cache.list_classes()) == Repo.aggregate(Class, :count)
    end
  end
end
