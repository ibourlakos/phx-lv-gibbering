defmodule Gibbering.CatalogueTest do
  use Gibbering.DataCase, async: true

  alias Gibbering.Catalogue
  alias Gibbering.Catalogue.{Race, Class, Spell}

  defp insert_race(key) do
    Repo.insert!(%Race{
      key: key,
      name: "Dwarf",
      description: "Stout and resilient mountain folk.",
      speed: 25,
      stat_bonuses: %{"constitution" => 2},
      traits: [],
      darkvision: true
    })
  end

  defp insert_class(key) do
    Repo.insert!(%Class{
      key: key,
      name: "Paladin",
      description: "Holy warrior sworn to a sacred oath.",
      hit_die: "d10",
      base_hp: 10,
      primary_stats: ["strength", "charisma"],
      saving_throws: ["wisdom", "charisma"],
      armor_proficiencies: ["light", "medium", "heavy", "shields"],
      weapon_proficiencies: ["simple", "martial"],
      spellcasting: true,
      spells: [],
      features: [],
      stats: %{"strength" => 16, "charisma" => 14}
    })
  end

  defp insert_spell(key) do
    Repo.insert!(%Spell{
      key: key,
      name: "Shatter",
      level: 2,
      school: "evocation",
      casting_time: "1 action",
      range: "60",
      description: "10-ft sphere of sound. Con save or 3d8 thunder damage.",
      damage_dice: "3d8",
      damage_type: "thunder",
      attack_type: "save",
      save: "constitution",
      tags: ["offensive", "aoe"]
    })
  end

  describe "get_race/1" do
    test "returns the race for a valid key" do
      insert_race("dwarf")
      assert %Race{key: "dwarf", name: "Dwarf"} = Catalogue.get_race("dwarf")
    end

    test "returns nil for an unknown key" do
      assert Catalogue.get_race("tiefling") == nil
    end
  end

  describe "get_class/1" do
    test "returns the class for a valid key" do
      insert_class("paladin")
      assert %Class{key: "paladin", base_hp: 10} = Catalogue.get_class("paladin")
    end

    test "returns nil for an unknown key" do
      assert Catalogue.get_class("bard") == nil
    end
  end

  describe "get_spell/1" do
    test "returns the spell for a valid key" do
      insert_spell("shatter")

      assert %Spell{key: "shatter", level: 2, damage_type: "thunder"} =
               Catalogue.get_spell("shatter")
    end

    test "returns nil for an unknown key" do
      assert Catalogue.get_spell("fireball") == nil
    end
  end

  describe "list_races/0" do
    test "returns all seeded races" do
      insert_race("dwarf")
      races = Catalogue.list_races()
      assert Enum.any?(races, &(&1.key == "dwarf"))
    end
  end
end
