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
    }
  }

  def seed_data, do: @seed_data
end
