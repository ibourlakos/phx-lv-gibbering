defmodule Gibbering.Data.Spells do
  @spells %{
    # Cantrips (level 0)
    "fire_bolt" => %{
      name: "Fire Bolt",
      level: 0,
      school: "evocation",
      casting_time: "1 action",
      range: 120,
      description: "Hurl a mote of fire at a creature or object. +5 to hit, 1d10 fire damage.",
      damage_dice: "1d10",
      damage_type: "fire",
      attack_type: :ranged,
      save: nil,
      tags: ["offensive", "ranged"]
    },
    "mage_hand" => %{
      name: "Mage Hand",
      level: 0,
      school: "conjuration",
      casting_time: "1 action",
      range: 30,
      description: "Create a spectral hand to manipulate objects at a distance.",
      damage_dice: nil,
      damage_type: nil,
      attack_type: :utility,
      save: nil,
      tags: ["utility"]
    },
    "minor_illusion" => %{
      name: "Minor Illusion",
      level: 0,
      school: "illusion",
      casting_time: "1 action",
      range: 30,
      description: "Create a sound or image to deceive enemies. Constitution save to disbelieve.",
      damage_dice: nil,
      damage_type: nil,
      attack_type: :utility,
      save: :investigation,
      tags: ["utility", "crowd-control"]
    },
    "sacred_flame" => %{
      name: "Sacred Flame",
      level: 0,
      school: "evocation",
      casting_time: "1 action",
      range: 60,
      description: "Flame descends on a creature. Dex save or take 1d8 radiant damage. No cover.",
      damage_dice: "1d8",
      damage_type: "radiant",
      attack_type: :save,
      save: :dexterity,
      tags: ["offensive", "ranged"]
    },
    # Level 1 spells
    "magic_missile" => %{
      name: "Magic Missile",
      level: 1,
      school: "evocation",
      casting_time: "1 action",
      range: 120,
      description: "Three darts of magical force, each dealing 1d4+1 force damage. Auto-hits.",
      damage_dice: "1d4+1",
      damage_type: "force",
      attack_type: :auto,
      save: nil,
      tags: ["offensive", "ranged", "auto-hit"]
    },
    "cure_wounds" => %{
      name: "Cure Wounds",
      level: 1,
      school: "evocation",
      casting_time: "1 action",
      range: :touch,
      description: "Touch a creature and restore 1d8+modifier HP.",
      damage_dice: "1d8",
      damage_type: "healing",
      attack_type: :touch,
      save: nil,
      tags: ["healing", "support"]
    },
    "burning_hands" => %{
      name: "Burning Hands",
      level: 1,
      school: "evocation",
      casting_time: "1 action",
      range: :cone_15,
      description: "Cone of flame, 15 ft. Dex save or 3d6 fire damage (half on save).",
      damage_dice: "3d6",
      damage_type: "fire",
      attack_type: :aoe,
      save: :dexterity,
      tags: ["offensive", "aoe"]
    },
    "sleep" => %{
      name: "Sleep",
      level: 1,
      school: "enchantment",
      casting_time: "1 action",
      range: 90,
      description: "Roll 5d8 — total HP that sleep can affect, weakest creatures first.",
      damage_dice: "5d8",
      damage_type: nil,
      attack_type: :aoe,
      save: nil,
      tags: ["crowd-control", "aoe"]
    },
    "thunderwave" => %{
      name: "Thunderwave",
      level: 1,
      school: "evocation",
      casting_time: "1 action",
      range: :cube_15,
      description: "15-ft cube. Con save or 2d8 thunder damage + pushed 10 ft (half on save).",
      damage_dice: "2d8",
      damage_type: "thunder",
      attack_type: :aoe,
      save: :constitution,
      tags: ["offensive", "aoe", "push"]
    }
  }

  def all, do: @spells
  def get(spell_key), do: Map.get(@spells, spell_key)
  def keys, do: Map.keys(@spells)

  def cantrips, do: Enum.filter(@spells, fn {_, s} -> s.level == 0 end) |> Map.new()
  def level1, do: Enum.filter(@spells, fn {_, s} -> s.level == 1 end) |> Map.new()
end
