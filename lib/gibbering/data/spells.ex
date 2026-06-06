defmodule Gibbering.Data.Spells do
  @moduledoc """
  Seed source for the spells catalogue table and runtime spell definitions.

  `seed_data/0` — flat string-key map for DB seeding (seeds.exs).
  `all/0`       — typed `%Spell{}` structs keyed by atom, for engine use.
  `get/1`       — single spell lookup by atom or string key.
  """

  alias Gibbering.Rulesets.DnD5e.Spell

  @seed_data %{
    "fire_bolt" => %{
      name: "Fire Bolt",
      level: 0,
      school: "evocation",
      casting_time: "1 action",
      range: "120",
      description: "Hurl a mote of fire at a creature or object. +5 to hit, 1d10 fire damage.",
      damage_dice: "1d10",
      damage_type: "fire",
      attack_type: "ranged",
      save: nil,
      tags: ["offensive", "ranged"]
    },
    "mage_hand" => %{
      name: "Mage Hand",
      level: 0,
      school: "conjuration",
      casting_time: "1 action",
      range: "30",
      description: "Create a spectral hand to manipulate objects at a distance.",
      damage_dice: nil,
      damage_type: nil,
      attack_type: "utility",
      save: nil,
      tags: ["utility"]
    },
    "minor_illusion" => %{
      name: "Minor Illusion",
      level: 0,
      school: "illusion",
      casting_time: "1 action",
      range: "30",
      description: "Create a sound or image to deceive enemies. Constitution save to disbelieve.",
      damage_dice: nil,
      damage_type: nil,
      attack_type: "utility",
      save: "investigation",
      tags: ["utility", "crowd-control"]
    },
    "sacred_flame" => %{
      name: "Sacred Flame",
      level: 0,
      school: "evocation",
      casting_time: "1 action",
      range: "60",
      description: "Flame descends on a creature. Dex save or take 1d8 radiant damage. No cover.",
      damage_dice: "1d8",
      damage_type: "radiant",
      attack_type: "save",
      save: "dexterity",
      tags: ["offensive", "ranged"]
    },
    "magic_missile" => %{
      name: "Magic Missile",
      level: 1,
      school: "evocation",
      casting_time: "1 action",
      range: "120",
      description: "Three darts of magical force, each dealing 1d4+1 force damage. Auto-hits.",
      damage_dice: "1d4+1",
      damage_type: "force",
      attack_type: "auto",
      save: nil,
      tags: ["offensive", "ranged", "auto-hit"]
    },
    "cure_wounds" => %{
      name: "Cure Wounds",
      level: 1,
      school: "evocation",
      casting_time: "1 action",
      range: "touch",
      description: "Touch a creature and restore 1d8+modifier HP.",
      damage_dice: "1d8",
      damage_type: "healing",
      attack_type: "touch",
      save: nil,
      tags: ["healing", "support"]
    },
    "burning_hands" => %{
      name: "Burning Hands",
      level: 1,
      school: "evocation",
      casting_time: "1 action",
      range: "cone_15",
      description: "Cone of flame, 15 ft. Dex save or 3d6 fire damage (half on save).",
      damage_dice: "3d6",
      damage_type: "fire",
      attack_type: "aoe",
      save: "dexterity",
      tags: ["offensive", "aoe"]
    },
    "sleep" => %{
      name: "Sleep",
      level: 1,
      school: "enchantment",
      casting_time: "1 action",
      range: "90",
      description: "Roll 5d8 — total HP that sleep can affect, weakest creatures first.",
      damage_dice: "5d8",
      damage_type: nil,
      attack_type: "aoe",
      save: nil,
      tags: ["crowd-control", "aoe"]
    },
    "thunderwave" => %{
      name: "Thunderwave",
      level: 1,
      school: "evocation",
      casting_time: "1 action",
      range: "cube_15",
      description: "15-ft cube. Con save or 2d8 thunder damage + pushed 10 ft (half on save).",
      damage_dice: "2d8",
      damage_type: "thunder",
      attack_type: "aoe",
      save: "constitution",
      tags: ["offensive", "aoe", "push"]
    }
  }

  def seed_data, do: @seed_data

  @doc "Returns all spells as typed `%Spell{}` structs keyed by atom."
  @spec all() :: %{atom() => Spell.t()}
  def all do
    %{
      fire_bolt: %Spell{
        key: :fire_bolt,
        name: "Fire Bolt",
        level: 0,
        school: :evocation,
        casting_time: {:action},
        range: {:feet, 120},
        target_area: %{shape: :point, size: nil},
        effect: %{
          description: "Hurl a mote of fire at a creature or object. 1d10 fire damage on hit.",
          damage_dice: "1d10",
          damage_type: :fire,
          attack_type: :ranged_attack,
          save: nil
        },
        components: [:verbal, :somatic],
        duration: %{value: "instantaneous", is_concentration: false},
        tags: ["offensive", "ranged"]
      },
      mage_hand: %Spell{
        key: :mage_hand,
        name: "Mage Hand",
        level: 0,
        school: :conjuration,
        casting_time: {:action},
        range: {:feet, 30},
        target_area: %{shape: :point, size: nil},
        effect: %{
          description: "Create a spectral hand to manipulate objects at a distance.",
          damage_dice: nil,
          damage_type: nil,
          attack_type: :utility,
          save: nil
        },
        components: [:verbal, :somatic],
        duration: %{value: "1 minute", is_concentration: false},
        tags: ["utility"]
      },
      minor_illusion: %Spell{
        key: :minor_illusion,
        name: "Minor Illusion",
        level: 0,
        school: :illusion,
        casting_time: {:action},
        range: {:feet, 30},
        target_area: %{shape: :point, size: nil},
        effect: %{
          description:
            "Create a sound or image to deceive enemies. Investigation check to disbelieve.",
          damage_dice: nil,
          damage_type: nil,
          attack_type: :utility,
          save: :investigation
        },
        components: [:somatic, :material],
        duration: %{value: "1 minute", is_concentration: false},
        tags: ["utility", "crowd-control"]
      },
      sacred_flame: %Spell{
        key: :sacred_flame,
        name: "Sacred Flame",
        level: 0,
        school: :evocation,
        casting_time: {:action},
        range: {:feet, 60},
        target_area: %{shape: :point, size: nil},
        effect: %{
          description:
            "Flame descends on a creature. Dex save or take 1d8 radiant damage. No cover.",
          damage_dice: "1d8",
          damage_type: :radiant,
          attack_type: :save,
          save: :dexterity
        },
        components: [:verbal, :somatic],
        duration: %{value: "instantaneous", is_concentration: false},
        tags: ["offensive", "ranged"]
      },
      magic_missile: %Spell{
        key: :magic_missile,
        name: "Magic Missile",
        level: 1,
        school: :evocation,
        casting_time: {:action},
        range: {:feet, 120},
        target_area: %{shape: :point, size: nil},
        effect: %{
          description:
            "Three darts of magical force, each dealing 1d4+1 force damage. Auto-hits.",
          damage_dice: "1d4+1",
          damage_type: :force,
          attack_type: :auto,
          save: nil
        },
        components: [:verbal, :somatic],
        duration: %{value: "instantaneous", is_concentration: false},
        tags: ["offensive", "ranged", "auto-hit"]
      },
      cure_wounds: %Spell{
        key: :cure_wounds,
        name: "Cure Wounds",
        level: 1,
        school: :evocation,
        casting_time: {:action},
        range: :touch,
        target_area: %{shape: :touch, size: nil},
        effect: %{
          description: "Touch a creature and restore 1d8 + modifier HP.",
          damage_dice: "1d8",
          damage_type: :healing,
          attack_type: :touch,
          save: nil
        },
        components: [:verbal, :somatic],
        duration: %{value: "instantaneous", is_concentration: false},
        tags: ["healing", "support"]
      },
      burning_hands: %Spell{
        key: :burning_hands,
        name: "Burning Hands",
        level: 1,
        school: :evocation,
        casting_time: {:action},
        range: :self,
        target_area: %{shape: :cone, size: 15},
        effect: %{
          description: "Cone of flame, 15 ft. Dex save or 3d6 fire damage (half on save).",
          damage_dice: "3d6",
          damage_type: :fire,
          attack_type: :save,
          save: :dexterity
        },
        components: [:verbal, :somatic],
        duration: %{value: "instantaneous", is_concentration: false},
        tags: ["offensive", "aoe"]
      },
      sleep: %Spell{
        key: :sleep,
        name: "Sleep",
        level: 1,
        school: :enchantment,
        casting_time: {:action},
        range: {:feet, 90},
        target_area: %{shape: :sphere, size: 20},
        effect: %{
          description: "Roll 5d8 — total HP that sleep can affect, weakest creatures first.",
          damage_dice: "5d8",
          damage_type: nil,
          attack_type: :aoe,
          save: nil
        },
        components: [:verbal, :somatic, :material],
        duration: %{value: "1 minute", is_concentration: false},
        tags: ["crowd-control", "aoe"]
      },
      thunderwave: %Spell{
        key: :thunderwave,
        name: "Thunderwave",
        level: 1,
        school: :evocation,
        casting_time: {:action},
        range: :self,
        target_area: %{shape: :cube, size: 15},
        effect: %{
          description:
            "15-ft cube. Con save or 2d8 thunder damage + pushed 10 ft (half on save).",
          damage_dice: "2d8",
          damage_type: :thunder,
          attack_type: :save,
          save: :constitution
        },
        components: [:verbal, :somatic],
        duration: %{value: "instantaneous", is_concentration: false},
        tags: ["offensive", "aoe", "push"]
      }
    }
  end

  @doc "Returns the `%Spell{}` for the given atom key, or nil."
  @spec get(atom()) :: Spell.t() | nil
  def get(key) when is_atom(key), do: Map.get(all(), key)

  @spec get(String.t()) :: Spell.t() | nil
  def get(key) when is_binary(key) do
    Enum.find_value(all(), fn {k, spell} ->
      if to_string(k) == key, do: spell
    end)
  end
end
