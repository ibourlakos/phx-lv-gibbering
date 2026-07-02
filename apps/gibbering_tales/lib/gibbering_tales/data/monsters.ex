defmodule GibberingTales.Data.Monsters do
  @moduledoc """
  Seed source for the monsters catalogue table.

  All entries are drawn from the D&D 5e SRD 5.1 (Creative Commons Attribution 4.0).
  source_license: "SRD 5.1 CC-BY-4.0" on every entry.
  """

  @seed_data %{
    "goblin" => %{
      name: "Goblin",
      size: "Small",
      monster_type: "humanoid",
      alignment: "neutral evil",
      armor_class: 15,
      hit_points: 7,
      hit_dice: "2d6",
      speed: %{"walk" => 30},
      strength: 8,
      dexterity: 14,
      constitution: 10,
      intelligence: 10,
      wisdom: 8,
      charisma: 8,
      challenge_rating: "1/4",
      xp_reward: 50,
      source_license: "SRD 5.1 CC-BY-4.0",
      stat_block: %{
        "actions" => [
          %{
            "name" => "Scimitar",
            "attack_bonus" => 4,
            "damage_dice" => "1d6+2",
            "damage_type" => "slashing"
          },
          %{
            "name" => "Shortbow",
            "attack_bonus" => 4,
            "damage_dice" => "1d6+2",
            "damage_type" => "piercing",
            "range" => "80/320"
          }
        ],
        "traits" => [
          %{
            "name" => "Nimble Escape",
            "description" => "Can take the Disengage or Hide action as a bonus action each turn."
          }
        ]
      }
    },
    "skeleton" => %{
      name: "Skeleton",
      size: "Medium",
      monster_type: "undead",
      alignment: "lawful evil",
      armor_class: 13,
      hit_points: 13,
      hit_dice: "2d8+4",
      speed: %{"walk" => 30},
      strength: 10,
      dexterity: 14,
      constitution: 15,
      intelligence: 6,
      wisdom: 8,
      charisma: 5,
      challenge_rating: "1/4",
      xp_reward: 50,
      source_license: "SRD 5.1 CC-BY-4.0",
      stat_block: %{
        "actions" => [
          %{
            "name" => "Shortsword",
            "attack_bonus" => 4,
            "damage_dice" => "1d6+2",
            "damage_type" => "piercing"
          },
          %{
            "name" => "Shortbow",
            "attack_bonus" => 4,
            "damage_dice" => "1d6+2",
            "damage_type" => "piercing",
            "range" => "80/320"
          }
        ],
        "immunities" => ["poison", "exhaustion", "frightened", "poisoned"],
        "vulnerabilities" => ["bludgeoning"]
      }
    },
    "zombie" => %{
      name: "Zombie",
      size: "Medium",
      monster_type: "undead",
      alignment: "neutral evil",
      armor_class: 8,
      hit_points: 22,
      hit_dice: "3d8+9",
      speed: %{"walk" => 20},
      strength: 13,
      dexterity: 6,
      constitution: 16,
      intelligence: 3,
      wisdom: 6,
      charisma: 5,
      challenge_rating: "1/4",
      xp_reward: 50,
      source_license: "SRD 5.1 CC-BY-4.0",
      stat_block: %{
        "actions" => [
          %{
            "name" => "Slam",
            "attack_bonus" => 3,
            "damage_dice" => "1d6+1",
            "damage_type" => "bludgeoning"
          }
        ],
        "traits" => [
          %{
            "name" => "Undead Fortitude",
            "description" =>
              "If reduced to 0 HP by damage other than radiant or a critical hit, make a CON save (DC 5 + damage taken). On success, drop to 1 HP instead."
          }
        ],
        "immunities" => ["poison", "poisoned"]
      }
    },
    "kobold" => %{
      name: "Kobold",
      size: "Small",
      monster_type: "humanoid",
      alignment: "lawful evil",
      armor_class: 12,
      hit_points: 5,
      hit_dice: "2d6-2",
      speed: %{"walk" => 30},
      strength: 7,
      dexterity: 15,
      constitution: 9,
      intelligence: 8,
      wisdom: 7,
      charisma: 8,
      challenge_rating: "1/8",
      xp_reward: 25,
      source_license: "SRD 5.1 CC-BY-4.0",
      stat_block: %{
        "actions" => [
          %{
            "name" => "Dagger",
            "attack_bonus" => 4,
            "damage_dice" => "1d4+2",
            "damage_type" => "piercing"
          },
          %{
            "name" => "Sling",
            "attack_bonus" => 4,
            "damage_dice" => "1d4+2",
            "damage_type" => "bludgeoning",
            "range" => "30/120"
          }
        ],
        "traits" => [
          %{
            "name" => "Pack Tactics",
            "description" => "Advantage on attack rolls when an ally is adjacent to the target."
          },
          %{
            "name" => "Sunlight Sensitivity",
            "description" => "Disadvantage on attack rolls and perception checks in sunlight."
          }
        ]
      }
    },
    "bandit" => %{
      name: "Bandit",
      size: "Medium",
      monster_type: "humanoid",
      alignment: "any non-lawful",
      armor_class: 12,
      hit_points: 11,
      hit_dice: "2d8+2",
      speed: %{"walk" => 30},
      strength: 11,
      dexterity: 12,
      constitution: 12,
      intelligence: 10,
      wisdom: 10,
      charisma: 10,
      challenge_rating: "1/8",
      xp_reward: 25,
      source_license: "SRD 5.1 CC-BY-4.0",
      stat_block: %{
        "actions" => [
          %{
            "name" => "Scimitar",
            "attack_bonus" => 3,
            "damage_dice" => "1d6+1",
            "damage_type" => "slashing"
          },
          %{
            "name" => "Light Crossbow",
            "attack_bonus" => 3,
            "damage_dice" => "1d8+1",
            "damage_type" => "piercing",
            "range" => "80/320"
          }
        ]
      }
    },
    "cultist" => %{
      name: "Cultist",
      size: "Medium",
      monster_type: "humanoid",
      alignment: "any non-good",
      armor_class: 12,
      hit_points: 9,
      hit_dice: "2d8",
      speed: %{"walk" => 30},
      strength: 11,
      dexterity: 12,
      constitution: 10,
      intelligence: 10,
      wisdom: 11,
      charisma: 10,
      challenge_rating: "1/8",
      xp_reward: 25,
      source_license: "SRD 5.1 CC-BY-4.0",
      stat_block: %{
        "actions" => [
          %{
            "name" => "Scimitar",
            "attack_bonus" => 3,
            "damage_dice" => "1d6+1",
            "damage_type" => "slashing"
          }
        ],
        "traits" => [
          %{
            "name" => "Dark Devotion",
            "description" => "Advantage on saving throws against being charmed or frightened."
          }
        ]
      }
    },
    "guard" => %{
      name: "Guard",
      size: "Medium",
      monster_type: "humanoid",
      alignment: "any",
      armor_class: 16,
      hit_points: 11,
      hit_dice: "2d8+2",
      speed: %{"walk" => 30},
      strength: 13,
      dexterity: 12,
      constitution: 12,
      intelligence: 10,
      wisdom: 11,
      charisma: 10,
      challenge_rating: "1/8",
      xp_reward: 25,
      source_license: "SRD 5.1 CC-BY-4.0",
      stat_block: %{
        "actions" => [
          %{
            "name" => "Spear",
            "attack_bonus" => 3,
            "damage_dice" => "1d6+1",
            "damage_type" => "piercing"
          }
        ]
      }
    },
    "wolf" => %{
      name: "Wolf",
      size: "Medium",
      monster_type: "beast",
      alignment: "unaligned",
      armor_class: 13,
      hit_points: 11,
      hit_dice: "2d8+2",
      speed: %{"walk" => 40},
      strength: 12,
      dexterity: 15,
      constitution: 12,
      intelligence: 3,
      wisdom: 12,
      charisma: 6,
      challenge_rating: "1/4",
      xp_reward: 50,
      source_license: "SRD 5.1 CC-BY-4.0",
      stat_block: %{
        "actions" => [
          %{
            "name" => "Bite",
            "attack_bonus" => 4,
            "damage_dice" => "2d4+2",
            "damage_type" => "piercing",
            "effect" => "target knocked prone on failed DC 11 STR save"
          }
        ],
        "traits" => [
          %{
            "name" => "Pack Tactics",
            "description" => "Advantage on attack rolls when an ally is adjacent to the target."
          },
          %{
            "name" => "Keen Hearing and Smell",
            "description" => "Advantage on Perception checks that rely on hearing or smell."
          }
        ]
      }
    },
    "orc" => %{
      name: "Orc",
      size: "Medium",
      monster_type: "humanoid",
      alignment: "chaotic evil",
      armor_class: 13,
      hit_points: 15,
      hit_dice: "2d8+6",
      speed: %{"walk" => 30},
      strength: 16,
      dexterity: 12,
      constitution: 16,
      intelligence: 7,
      wisdom: 11,
      charisma: 10,
      challenge_rating: "1/2",
      xp_reward: 100,
      source_license: "SRD 5.1 CC-BY-4.0",
      stat_block: %{
        "actions" => [
          %{
            "name" => "Greataxe",
            "attack_bonus" => 5,
            "damage_dice" => "1d12+3",
            "damage_type" => "slashing"
          },
          %{
            "name" => "Javelin",
            "attack_bonus" => 5,
            "damage_dice" => "1d6+3",
            "damage_type" => "piercing",
            "range" => "30/120"
          }
        ],
        "traits" => [
          %{
            "name" => "Aggressive",
            "description" =>
              "As a bonus action, the orc can move up to its speed toward a hostile creature."
          }
        ]
      }
    },
    "bugbear" => %{
      name: "Bugbear",
      size: "Medium",
      monster_type: "humanoid",
      alignment: "chaotic evil",
      armor_class: 16,
      hit_points: 27,
      hit_dice: "5d8+5",
      speed: %{"walk" => 30},
      strength: 15,
      dexterity: 14,
      constitution: 13,
      intelligence: 8,
      wisdom: 11,
      charisma: 9,
      challenge_rating: "1",
      xp_reward: 200,
      source_license: "SRD 5.1 CC-BY-4.0",
      stat_block: %{
        "actions" => [
          %{
            "name" => "Morningstar",
            "attack_bonus" => 4,
            "damage_dice" => "2d8+2",
            "damage_type" => "piercing"
          },
          %{
            "name" => "Javelin",
            "attack_bonus" => 4,
            "damage_dice" => "2d6+2",
            "damage_type" => "piercing",
            "range" => "30/120"
          }
        ],
        "traits" => [
          %{
            "name" => "Brute",
            "description" => "A melee weapon deals one extra die of damage (included above)."
          },
          %{
            "name" => "Surprise Attack",
            "description" => "On first hit against a surprised creature, +7 damage (2d6)."
          }
        ]
      }
    },
    "ogre" => %{
      name: "Ogre",
      size: "Large",
      monster_type: "giant",
      alignment: "chaotic evil",
      armor_class: 11,
      hit_points: 59,
      hit_dice: "7d10+21",
      speed: %{"walk" => 40},
      strength: 19,
      dexterity: 8,
      constitution: 16,
      intelligence: 5,
      wisdom: 7,
      charisma: 7,
      challenge_rating: "2",
      xp_reward: 450,
      source_license: "SRD 5.1 CC-BY-4.0",
      stat_block: %{
        "actions" => [
          %{
            "name" => "Greatclub",
            "attack_bonus" => 6,
            "damage_dice" => "2d8+4",
            "damage_type" => "bludgeoning"
          },
          %{
            "name" => "Javelin",
            "attack_bonus" => 6,
            "damage_dice" => "2d6+4",
            "damage_type" => "piercing",
            "range" => "30/120"
          }
        ]
      }
    },
    "troll" => %{
      name: "Troll",
      size: "Large",
      monster_type: "giant",
      alignment: "chaotic evil",
      armor_class: 15,
      hit_points: 84,
      hit_dice: "8d10+40",
      speed: %{"walk" => 30},
      strength: 18,
      dexterity: 13,
      constitution: 20,
      intelligence: 7,
      wisdom: 9,
      charisma: 7,
      challenge_rating: "5",
      xp_reward: 1800,
      source_license: "SRD 5.1 CC-BY-4.0",
      stat_block: %{
        "actions" => [
          %{"name" => "Multiattack", "description" => "Bite + 2 Claw attacks."},
          %{
            "name" => "Bite",
            "attack_bonus" => 7,
            "damage_dice" => "1d6+4",
            "damage_type" => "piercing"
          },
          %{
            "name" => "Claw",
            "attack_bonus" => 7,
            "damage_dice" => "2d6+4",
            "damage_type" => "slashing"
          }
        ],
        "traits" => [
          %{
            "name" => "Keen Smell",
            "description" => "Advantage on Perception checks that rely on smell."
          },
          %{
            "name" => "Regeneration",
            "description" =>
              "Regain 10 HP at the start of each turn. Does not work if the troll took acid or fire damage since last turn. Dies only if at 0 HP and not regenerating."
          }
        ]
      }
    }
  }

  @doc false
  def seed_data, do: @seed_data
end
