defmodule Gibbering.Data.Races do
  @moduledoc "Seed source for the races catalogue table. Runtime reads go through Gibbering.Catalogue.Cache."

  @seed_data %{
    "human" => %{
      name: "Human",
      description: "Versatile and ambitious, humans adapt quickly and excel in any calling.",
      speed: 30,
      stat_bonuses: %{
        "strength" => 1,
        "dexterity" => 1,
        "constitution" => 1,
        "intelligence" => 1,
        "wisdom" => 1,
        "charisma" => 1
      },
      traits: [
        %{name: "Skilled", description: "Gain proficiency in one extra skill of your choice."},
        %{
          name: "Extra Language",
          description: "You can speak, read, and write one extra language."
        }
      ],
      darkvision: false
    },
    "elf" => %{
      name: "Elf",
      description: "Ancient and graceful, elves move through the world with supernatural ease.",
      speed: 30,
      stat_bonuses: %{"dexterity" => 2, "intelligence" => 1},
      traits: [
        %{
          name: "Darkvision",
          description: "See in dim light within 60 ft as if bright; darkness as dim."
        },
        %{name: "Keen Senses", description: "Proficiency in the Perception skill."},
        %{
          name: "Fey Ancestry",
          description:
            "Advantage on saving throws against being charmed; magic can't put you to sleep."
        },
        %{
          name: "Trance",
          description: "Elves don't sleep; they meditate for 4 hours instead of 8."
        }
      ],
      darkvision: true
    },
    "gnome" => %{
      name: "Gnome",
      description: "Small but sharp-minded, gnomes are natural tinkerers and quick thinkers.",
      speed: 25,
      stat_bonuses: %{"intelligence" => 2, "constitution" => 1},
      traits: [
        %{
          name: "Darkvision",
          description: "See in dim light within 60 ft as if bright; darkness as dim."
        },
        %{
          name: "Gnome Cunning",
          description:
            "Advantage on all Intelligence, Wisdom, and Charisma saving throws against magic."
        },
        %{
          name: "Artificer's Lore",
          description: "+2 bonus to History checks related to magic items, alchemy, or tech."
        }
      ],
      darkvision: true
    },
    "dwarf" => %{
      name: "Dwarf",
      description: "Hardy and resilient, dwarves are skilled craftspeople and fierce warriors.",
      speed: 25,
      stat_bonuses: %{"constitution" => 2, "wisdom" => 1},
      traits: [
        %{
          name: "Darkvision",
          description: "See in dim light within 60 ft as if bright; darkness as dim."
        },
        %{
          name: "Dwarven Resilience",
          description: "Advantage on saving throws against poison; resistance to poison damage."
        },
        %{name: "Stonecunning", description: "+2 bonus to History checks related to stonework."},
        %{
          name: "Dwarven Combat Training",
          description: "Proficiency with battleaxe, handaxe, light hammer, and warhammer."
        }
      ],
      darkvision: true
    },
    "half_elf" => %{
      name: "Half-Elf",
      description: "Bridging two worlds, half-elves inherit elven grace and human ambition.",
      speed: 30,
      stat_bonuses: %{"charisma" => 2, "dexterity" => 1, "constitution" => 1},
      traits: [
        %{
          name: "Darkvision",
          description: "See in dim light within 60 ft as if bright; darkness as dim."
        },
        %{
          name: "Fey Ancestry",
          description:
            "Advantage on saving throws against being charmed; magic can't put you to sleep."
        },
        %{
          name: "Skill Versatility",
          description: "Gain proficiency in two skills of your choice."
        }
      ],
      darkvision: true
    },
    "halfling" => %{
      name: "Halfling",
      description:
        "Small, cheerful, and lucky beyond reason — halflings thrive where others stumble.",
      speed: 25,
      stat_bonuses: %{"dexterity" => 2, "charisma" => 1},
      traits: [
        %{
          name: "Lucky",
          description: "When you roll a 1 on a d20, reroll and use the new result."
        },
        %{name: "Brave", description: "Advantage on saving throws against being frightened."},
        %{
          name: "Halfling Nimbleness",
          description: "Move through the space of any creature larger than you."
        }
      ],
      darkvision: false
    },
    "tiefling" => %{
      name: "Tiefling",
      description: "Touched by infernal heritage, tieflings carry fiendish power in human form.",
      speed: 30,
      stat_bonuses: %{"intelligence" => 1, "charisma" => 2},
      traits: [
        %{
          name: "Darkvision",
          description: "See in dim light within 60 ft as if bright; darkness as dim."
        },
        %{name: "Hellish Resistance", description: "Resistance to fire damage."},
        %{
          name: "Infernal Legacy",
          description:
            "Know the Thaumaturgy cantrip; at 3rd level cast Hellish Rebuke 1/day; at 5th level Darkness 1/day."
        }
      ],
      darkvision: true
    },
    "dragonborn" => %{
      name: "Dragonborn",
      description:
        "Born of draconic lineage, dragonborn breathe elemental power and carry ancient pride.",
      speed: 30,
      stat_bonuses: %{"strength" => 2, "charisma" => 1},
      traits: [
        %{
          name: "Breath Weapon",
          description:
            "Exhale destructive energy matching your draconic ancestry (15 ft cone or 30 ft line); save DC 8 + CON mod + proficiency."
        },
        %{
          name: "Damage Resistance",
          description: "Resistance to the damage type of your draconic ancestry."
        },
        %{
          name: "Draconic Ancestry",
          description:
            "Choose a dragon type at character creation; this determines your breath weapon element and resistance."
        }
      ],
      darkvision: false
    },
    "half_orc" => %{
      name: "Half-Orc",
      description:
        "Powerful and tenacious, half-orcs combine orcish ferocity with human adaptability.",
      speed: 30,
      stat_bonuses: %{"strength" => 2, "constitution" => 1},
      traits: [
        %{
          name: "Darkvision",
          description: "See in dim light within 60 ft as if bright; darkness as dim."
        },
        %{name: "Menacing", description: "Proficiency in the Intimidation skill."},
        %{
          name: "Relentless Endurance",
          description:
            "When reduced to 0 HP but not killed, drop to 1 HP instead. Once per long rest."
        },
        %{
          name: "Savage Attacks",
          description:
            "When you score a critical hit with a melee weapon attack, roll one extra damage die."
        }
      ],
      darkvision: true
    }
  }

  @doc false
  def seed_data, do: @seed_data

  @doc "Returns combat-relevant `%RuleModifier{}` structs for the given race."
  def modifiers(race)

  def modifiers("elf") do
    alias GibberingEngine.RuleModifier

    [
      %RuleModifier{
        id: :elf_darkvision,
        name: "Darkvision",
        source: :elf,
        trigger: :passive,
        predicate: {:always},
        effect: {:grant_sense, :darkvision, 60},
        stacking: :binary_flag
      },
      %RuleModifier{
        id: :elf_fey_ancestry,
        name: "Fey Ancestry",
        source: :elf,
        trigger: {:on_saving_throw, :any},
        predicate: {:saving_throw_ability_is, :wisdom},
        effect: {:grant_advantage, :saving_throw},
        stacking: :binary_flag
      }
    ]
  end

  def modifiers("gnome") do
    alias GibberingEngine.RuleModifier

    [
      %RuleModifier{
        id: :gnome_darkvision,
        name: "Darkvision",
        source: :gnome,
        trigger: :passive,
        predicate: {:always},
        effect: {:grant_sense, :darkvision, 60},
        stacking: :binary_flag
      },
      %RuleModifier{
        id: :gnome_cunning,
        name: "Gnome Cunning",
        source: :gnome,
        trigger: {:on_saving_throw, :any},
        predicate:
          {:any_of,
           [
             {:saving_throw_ability_is, :intelligence},
             {:saving_throw_ability_is, :wisdom},
             {:saving_throw_ability_is, :charisma}
           ]},
        effect: {:grant_advantage, :saving_throw},
        stacking: :binary_flag
      }
    ]
  end

  def modifiers(_race), do: []
end
