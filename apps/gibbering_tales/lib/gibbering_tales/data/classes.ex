defmodule GibberingTales.Data.Classes do
  @moduledoc "Seed source for the classes catalogue table. Runtime reads go through GibberingTales.Catalogue.Cache."

  @seed_data %{
    "fighter" => %{
      name: "Fighter",
      description: "Masters of martial combat, skilled with weapons and armor.",
      hit_die: "d10",
      base_hp: 10,
      primary_stats: ["strength", "constitution"],
      saving_throws: ["strength", "constitution"],
      armor_proficiencies: ["light", "medium", "heavy", "shields"],
      weapon_proficiencies: ["simple", "martial"],
      spellcasting: false,
      spells: [],
      features: [
        %{
          name: "Second Wind",
          description: "Once per short rest, use a bonus action to regain 1d10+level HP."
        },
        %{
          name: "Action Surge",
          description: "Once per short rest, take one additional action on your turn."
        },
        %{name: "Fighting Style: Defense", description: "+1 AC while wearing armor."}
      ],
      stats: %{
        "strength" => 16,
        "dexterity" => 12,
        "constitution" => 14,
        "intelligence" => 8,
        "wisdom" => 10,
        "charisma" => 8
      }
    },
    "wizard" => %{
      name: "Wizard",
      description: "Scholars of arcane magic who channel power through careful study.",
      hit_die: "d6",
      base_hp: 6,
      primary_stats: ["intelligence", "wisdom"],
      saving_throws: ["intelligence", "wisdom"],
      armor_proficiencies: [],
      weapon_proficiencies: ["daggers", "darts", "slings", "quarterstaffs", "light crossbows"],
      spellcasting: true,
      spells: ["fire_bolt", "mage_hand", "magic_missile", "sleep"],
      features: [
        %{
          name: "Arcane Recovery",
          description: "Once per day after a short rest, recover expended spell slots."
        },
        %{
          name: "Spellcasting",
          description: "Cast spells using Intelligence as your spellcasting ability."
        },
        %{
          name: "Ritual Casting",
          description: "Cast wizard spells as rituals if they have the ritual tag."
        }
      ],
      stats: %{
        "strength" => 8,
        "dexterity" => 12,
        "constitution" => 12,
        "intelligence" => 18,
        "wisdom" => 14,
        "charisma" => 10
      }
    },
    "rogue" => %{
      name: "Rogue",
      description: "Cunning tricksters who rely on skill, stealth, and enemy vulnerability.",
      hit_die: "d8",
      base_hp: 8,
      primary_stats: ["dexterity", "intelligence"],
      saving_throws: ["dexterity", "intelligence"],
      armor_proficiencies: ["light"],
      weapon_proficiencies: ["simple", "hand_crossbows", "longswords", "rapiers", "shortswords"],
      spellcasting: false,
      spells: [],
      features: [
        %{
          name: "Sneak Attack",
          description: "Deal 1d6 extra damage when you have advantage or a flanking ally."
        },
        %{
          name: "Thieves' Cant",
          description: "A secret mix of dialect, jargon, and code understood by rogues."
        },
        %{
          name: "Expertise",
          description: "Double proficiency bonus for two skills of your choice."
        }
      ],
      stats: %{
        "strength" => 10,
        "dexterity" => 16,
        "constitution" => 12,
        "intelligence" => 14,
        "wisdom" => 12,
        "charisma" => 12
      }
    },
    "barbarian" => %{
      name: "Barbarian",
      description:
        "Fierce warriors who channel primal rage to shrug off pain and deal devastating blows.",
      hit_die: "d12",
      base_hp: 12,
      primary_stats: ["strength", "constitution"],
      saving_throws: ["strength", "constitution"],
      armor_proficiencies: ["light", "medium", "shields"],
      weapon_proficiencies: ["simple", "martial"],
      spellcasting: false,
      spells: [],
      features: [
        %{
          name: "Rage",
          description:
            "Enter a rage as a bonus action. While raging: advantage on STR checks/saves, +2 melee damage, resistance to bludgeoning/piercing/slashing. Lasts 1 min. 2/long rest at level 1."
        },
        %{
          name: "Unarmored Defense",
          description: "While not wearing armor, AC = 10 + DEX mod + CON mod."
        },
        %{
          name: "Reckless Attack",
          description:
            "On your first attack each turn, gain advantage; attackers have advantage against you until next turn."
        }
      ],
      stats: %{
        "strength" => 17,
        "dexterity" => 13,
        "constitution" => 16,
        "intelligence" => 8,
        "wisdom" => 11,
        "charisma" => 9
      }
    },
    "bard" => %{
      name: "Bard",
      description: "Inspired performers who weave magic through music, stories, and bardic wit.",
      hit_die: "d8",
      base_hp: 8,
      primary_stats: ["charisma", "dexterity"],
      saving_throws: ["dexterity", "charisma"],
      armor_proficiencies: ["light"],
      weapon_proficiencies: ["simple", "hand_crossbows", "longswords", "rapiers", "shortswords"],
      spellcasting: true,
      spells: ["mage_hand", "fire_bolt"],
      features: [
        %{
          name: "Bardic Inspiration",
          description:
            "Use a bonus action to grant a d6 inspiration die to another creature within 60 ft. 1/short rest per CHA modifier."
        },
        %{
          name: "Spellcasting",
          description: "Cast spells using Charisma as your spellcasting ability."
        },
        %{
          name: "Jack of All Trades",
          description:
            "Add half your proficiency bonus (rounded down) to any ability check not already proficient."
        }
      ],
      stats: %{
        "strength" => 8,
        "dexterity" => 14,
        "constitution" => 12,
        "intelligence" => 12,
        "wisdom" => 12,
        "charisma" => 18
      }
    },
    "cleric" => %{
      name: "Cleric",
      description:
        "Divine intermediaries who channel the power of their deity to heal, protect, and smite.",
      hit_die: "d8",
      base_hp: 8,
      primary_stats: ["wisdom", "constitution"],
      saving_throws: ["wisdom", "charisma"],
      armor_proficiencies: ["light", "medium", "shields"],
      weapon_proficiencies: ["simple"],
      spellcasting: true,
      spells: ["fire_bolt", "mage_hand", "magic_missile", "sleep"],
      features: [
        %{
          name: "Spellcasting",
          description:
            "Cast spells using Wisdom as your spellcasting ability. Prepare spells each day after a long rest."
        },
        %{
          name: "Divine Domain",
          description:
            "Choose a domain at level 1 (Life, Light, War, etc.); gain domain spells and channel divinity options."
        },
        %{
          name: "Channel Divinity",
          description: "Expend a channel divinity charge to power divine effects. 1/short rest."
        }
      ],
      stats: %{
        "strength" => 12,
        "dexterity" => 10,
        "constitution" => 14,
        "intelligence" => 10,
        "wisdom" => 18,
        "charisma" => 14
      }
    },
    "druid" => %{
      name: "Druid",
      description:
        "Guardians of nature who draw power from the wild to cast spells and transform into beasts.",
      hit_die: "d8",
      base_hp: 8,
      primary_stats: ["wisdom", "constitution"],
      saving_throws: ["intelligence", "wisdom"],
      armor_proficiencies: ["light", "medium", "shields"],
      weapon_proficiencies: [
        "clubs",
        "daggers",
        "darts",
        "javelins",
        "maces",
        "quarterstaffs",
        "scimitars",
        "sickles",
        "slings",
        "spears"
      ],
      spellcasting: true,
      spells: ["fire_bolt", "mage_hand"],
      features: [
        %{
          name: "Spellcasting",
          description:
            "Cast spells using Wisdom as your spellcasting ability. Prepare spells daily."
        },
        %{
          name: "Wild Shape",
          description:
            "Use action to transform into a beast you have seen. CR ≤ 1/4 at level 2; higher CR as you level. 2/short rest."
        },
        %{
          name: "Druidic",
          description:
            "Know Druidic, the secret language of druids. Leaves hidden messages only druids can see."
        }
      ],
      stats: %{
        "strength" => 10,
        "dexterity" => 12,
        "constitution" => 14,
        "intelligence" => 12,
        "wisdom" => 18,
        "charisma" => 10
      }
    },
    "monk" => %{
      name: "Monk",
      description:
        "Disciplined martial artists who harness ki to perform superhuman feats of combat.",
      hit_die: "d8",
      base_hp: 8,
      primary_stats: ["dexterity", "wisdom"],
      saving_throws: ["strength", "dexterity"],
      armor_proficiencies: [],
      weapon_proficiencies: ["simple", "shortswords"],
      spellcasting: false,
      spells: [],
      features: [
        %{
          name: "Martial Arts",
          description:
            "Use DEX instead of STR for unarmed attacks; unarmed damage = 1d4 at level 1, increasing with level."
        },
        %{
          name: "Unarmored Defense",
          description: "While not wearing armor or shield, AC = 10 + DEX mod + WIS mod."
        },
        %{
          name: "Ki",
          description:
            "Spend ki points (= level) to fuel monk abilities: Flurry of Blows, Patient Defense, Step of the Wind."
        }
      ],
      stats: %{
        "strength" => 10,
        "dexterity" => 18,
        "constitution" => 13,
        "intelligence" => 10,
        "wisdom" => 16,
        "charisma" => 8
      }
    },
    "paladin" => %{
      name: "Paladin",
      description:
        "Holy warriors bound by sacred oaths, combining martial might with divine magic.",
      hit_die: "d10",
      base_hp: 10,
      primary_stats: ["strength", "charisma"],
      saving_throws: ["wisdom", "charisma"],
      armor_proficiencies: ["light", "medium", "heavy", "shields"],
      weapon_proficiencies: ["simple", "martial"],
      spellcasting: true,
      spells: ["magic_missile"],
      features: [
        %{
          name: "Divine Smite",
          description:
            "When you hit with a melee weapon attack, expend a spell slot to deal 2d8 radiant damage + 1d8 per slot level above 1st."
        },
        %{
          name: "Lay on Hands",
          description:
            "Pool of HP = 5 × level. Use an action to restore HP from the pool, or expend 5 HP to cure a disease or poison."
        },
        %{
          name: "Sacred Oath",
          description:
            "Swear an oath at level 3 (Devotion, Ancients, Vengeance) granting tenets, Channel Divinity options, and spells."
        }
      ],
      stats: %{
        "strength" => 17,
        "dexterity" => 10,
        "constitution" => 14,
        "intelligence" => 9,
        "wisdom" => 12,
        "charisma" => 16
      }
    },
    "ranger" => %{
      name: "Ranger",
      description:
        "Skilled hunters of the wilderness, blending martial skill with limited nature magic.",
      hit_die: "d10",
      base_hp: 10,
      primary_stats: ["dexterity", "wisdom"],
      saving_throws: ["strength", "dexterity"],
      armor_proficiencies: ["light", "medium", "shields"],
      weapon_proficiencies: ["simple", "martial"],
      spellcasting: true,
      spells: ["magic_missile"],
      features: [
        %{
          name: "Natural Explorer",
          description:
            "Choose a favored terrain; gain doubled proficiency on related checks, no difficult terrain penalty, can't be lost."
        },
        %{
          name: "Favored Enemy",
          description:
            "Choose an enemy type; advantage on survival checks to track them, and intelligence checks to recall information."
        },
        %{
          name: "Spellcasting",
          description:
            "Cast ranger spells using Wisdom. Half-caster (spell slots advance slower than full casters)."
        }
      ],
      stats: %{
        "strength" => 12,
        "dexterity" => 17,
        "constitution" => 13,
        "intelligence" => 10,
        "wisdom" => 15,
        "charisma" => 8
      }
    },
    "sorcerer" => %{
      name: "Sorcerer",
      description: "Innate spellcasters whose magic surges from within — born, not learned.",
      hit_die: "d6",
      base_hp: 6,
      primary_stats: ["charisma", "constitution"],
      saving_throws: ["constitution", "charisma"],
      armor_proficiencies: [],
      weapon_proficiencies: ["daggers", "darts", "slings", "quarterstaffs", "light_crossbows"],
      spellcasting: true,
      spells: ["fire_bolt", "mage_hand", "magic_missile", "sleep"],
      features: [
        %{
          name: "Spellcasting",
          description: "Cast spells using Charisma as your spellcasting ability."
        },
        %{
          name: "Sorcerous Origin",
          description:
            "Choose an origin at level 1 (Draconic Bloodline, Wild Magic) granting bonus spells and powers."
        },
        %{
          name: "Metamagic",
          description:
            "At level 3, spend sorcery points to modify spells: Empower, Extend, Twin, Quicken, and others."
        }
      ],
      stats: %{
        "strength" => 8,
        "dexterity" => 13,
        "constitution" => 13,
        "intelligence" => 12,
        "wisdom" => 12,
        "charisma" => 18
      }
    },
    "warlock" => %{
      name: "Warlock",
      description:
        "Seekers of dark knowledge who strike pacts with powerful otherworldly patrons.",
      hit_die: "d8",
      base_hp: 8,
      primary_stats: ["charisma", "constitution"],
      saving_throws: ["wisdom", "charisma"],
      armor_proficiencies: ["light"],
      weapon_proficiencies: ["simple"],
      spellcasting: true,
      spells: ["fire_bolt", "mage_hand"],
      features: [
        %{
          name: "Otherworldly Patron",
          description:
            "Choose a patron at level 1 (Archfey, Fiend, Great Old One); gain patron spells and expanded spell list."
        },
        %{
          name: "Pact Magic",
          description:
            "Cast spells using Charisma. Warlock slots recharge on short rest; only 1–2 slots at most levels."
        },
        %{
          name: "Eldritch Invocations",
          description:
            "At level 2 choose magical invocations granting persistent magical abilities (e.g. Agonizing Blast, Devil's Sight)."
        }
      ],
      stats: %{
        "strength" => 8,
        "dexterity" => 13,
        "constitution" => 13,
        "intelligence" => 12,
        "wisdom" => 12,
        "charisma" => 18
      }
    }
  }

  @doc false
  def seed_data, do: @seed_data

  @doc "Returns combat-relevant `%RuleModifier{}` structs for the given class."
  def modifiers(class)

  def modifiers("fighter") do
    alias GibberingEngine.RuleModifier

    [
      %RuleModifier{
        id: :fighter_second_wind,
        name: "Second Wind",
        source: :fighter,
        trigger: :on_second_wind,
        predicate: {:entity_has_resource, :second_wind},
        effect: {:restore_hp, "1d10"},
        stacking: :named_bonus
      },
      %RuleModifier{
        id: :fighter_action_surge,
        name: "Action Surge",
        source: :fighter,
        trigger: :on_action_surge,
        predicate: {:entity_has_resource, :action_surge},
        effect: {:grant_extra_action},
        stacking: :named_bonus,
        min_level: 2
      }
    ]
  end

  def modifiers("rogue") do
    alias GibberingEngine.RuleModifier

    [
      %RuleModifier{
        id: :rogue_sneak_attack,
        name: "Sneak Attack",
        source: :rogue,
        trigger: {:on_attack, :any},
        predicate: {:any_of, [{:ally_adjacent_to_target}, {:entity_and_ally_flank_target}]},
        effect: {:add_damage_dice, "1d6", :sneak_attack},
        stacking: :named_bonus
      }
    ]
  end

  def modifiers("barbarian") do
    alias GibberingEngine.RuleModifier

    [
      %RuleModifier{
        id: :barbarian_rage_damage,
        name: "Rage",
        source: :barbarian,
        trigger: {:on_attack, :melee},
        predicate: {:entity_has_condition, :raging},
        effect: {:add_bonus, :damage, 2},
        stacking: :additive
      }
    ]
  end

  def modifiers(_class), do: []
end
