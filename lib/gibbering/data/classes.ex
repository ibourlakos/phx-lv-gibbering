defmodule Gibbering.Data.Classes do
  @moduledoc "Seed source for the classes catalogue table. Runtime reads go through Gibbering.Catalogue.Cache."

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
    }
  }

  def seed_data, do: @seed_data

  @doc "Returns combat-relevant `%RuleModifier{}` structs for the given class."
  def modifiers(class)

  def modifiers("fighter") do
    alias Gibbering.Rulesets.DnD5e.RuleModifier

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
    alias Gibbering.Rulesets.DnD5e.RuleModifier

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
    alias Gibbering.Rulesets.DnD5e.RuleModifier

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
