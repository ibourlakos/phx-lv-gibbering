defmodule GibberingTales.Rulesets.DnD5e.StatsTest do
  use ExUnit.Case, async: true

  alias GibberingTales.Rulesets.DnD5e.Stats

  describe "ability_modifier/1" do
    test "score 10 gives 0" do
      assert Stats.ability_modifier(10) == 0
    end

    test "score 11 gives 0" do
      assert Stats.ability_modifier(11) == 0
    end

    test "score 12 gives +1" do
      assert Stats.ability_modifier(12) == 1
    end

    test "score 8 gives -1" do
      assert Stats.ability_modifier(8) == -1
    end

    test "score 1 gives -5" do
      assert Stats.ability_modifier(1) == -5
    end

    test "score 20 gives +5" do
      assert Stats.ability_modifier(20) == 5
    end

    test "score 30 gives +10" do
      assert Stats.ability_modifier(30) == 10
    end
  end

  describe "proficiency_bonus/1" do
    test "level 1 gives +2" do
      assert Stats.proficiency_bonus(1) == 2
    end

    test "level 4 gives +2" do
      assert Stats.proficiency_bonus(4) == 2
    end

    test "level 5 gives +3" do
      assert Stats.proficiency_bonus(5) == 3
    end

    test "level 8 gives +3" do
      assert Stats.proficiency_bonus(8) == 3
    end

    test "level 9 gives +4" do
      assert Stats.proficiency_bonus(9) == 4
    end

    test "level 13 gives +5" do
      assert Stats.proficiency_bonus(13) == 5
    end

    test "level 17 gives +6" do
      assert Stats.proficiency_bonus(17) == 6
    end

    test "level 20 gives +6" do
      assert Stats.proficiency_bonus(20) == 6
    end
  end

  describe "armor_class/1" do
    test "returns base_ac from equipped heavy armor" do
      entity =
        entity_with_stats(%{
          "dexterity" => 12,
          "equipped_armor" => %{"base_ac" => 16, "armor_category" => "heavy"}
        })

      assert Stats.armor_class(entity) == 16
    end

    test "returns base_ac + dex_mod for light armor" do
      entity =
        entity_with_stats(%{
          "dexterity" => 14,
          "equipped_armor" => %{"base_ac" => 11, "armor_category" => "light"}
        })

      assert Stats.armor_class(entity) == 13
    end

    test "returns base_ac + min(dex_mod, 2) for medium armor" do
      entity =
        entity_with_stats(%{
          "dexterity" => 18,
          "equipped_armor" => %{"base_ac" => 14, "armor_category" => "medium"}
        })

      assert Stats.armor_class(entity) == 16
    end

    test "medium armor caps dex bonus at +2" do
      entity =
        entity_with_stats(%{
          "dexterity" => 22,
          "equipped_armor" => %{"base_ac" => 14, "armor_category" => "medium"}
        })

      assert Stats.armor_class(entity) == 16
    end

    test "falls back to 10 + dex_mod when no armor" do
      entity =
        entity_with_stats(%{
          "dexterity" => 14,
          "equipped_armor" => %{"base_ac" => nil, "armor_category" => "none"}
        })

      assert Stats.armor_class(entity) == 12
    end

    test "falls back to 10 + dex_mod when equipped_armor absent" do
      entity = entity_with_stats(%{"dexterity" => 16})
      assert Stats.armor_class(entity) == 13
    end
  end

  describe "attack_bonus/2" do
    test "melee uses str_modifier + proficiency_bonus" do
      entity = entity_with(%{level: 3, stats: %{"strength" => 17, "dexterity" => 13}})
      # str_mod = +3, prof = +2
      assert Stats.attack_bonus(entity, :melee) == 5
    end

    test "ranged uses dex_modifier + proficiency_bonus" do
      entity = entity_with(%{level: 1, stats: %{"strength" => 10, "dexterity" => 16}})
      # dex_mod = +3, prof = +2
      assert Stats.attack_bonus(entity, :ranged) == 5
    end

    test "spell uses spellcasting ability modifier + proficiency_bonus for wizard (int)" do
      entity =
        entity_with(%{
          level: 3,
          class: "wizard",
          stats: %{"intelligence" => 20, "wisdom" => 14}
        })

      # int_mod = +5, prof = +2
      assert Stats.attack_bonus(entity, :spell) == 7
    end

    test "higher level increases proficiency bonus component" do
      entity = entity_with(%{level: 5, stats: %{"strength" => 17, "dexterity" => 13}})
      # str_mod = +3, prof = +3
      assert Stats.attack_bonus(entity, :melee) == 6
    end
  end

  describe "spell_dc/1" do
    test "8 + proficiency_bonus + spellcasting_modifier for wizard" do
      entity =
        entity_with(%{
          level: 3,
          class: "wizard",
          stats: %{"intelligence" => 20}
        })

      # 8 + 2 + 5 = 15
      assert Stats.spell_dc(entity) == 15
    end
  end

  describe "hydrate_entity/1" do
    test "adds ability_modifiers map" do
      entity =
        entity_with(%{
          level: 1,
          stats: %{
            "strength" => 17,
            "dexterity" => 13,
            "constitution" => 15,
            "intelligence" => 9,
            "wisdom" => 11,
            "charisma" => 9
          }
        })

      hydrated = Stats.hydrate_entity(entity)

      assert hydrated.ability_modifiers == %{
               "strength" => 3,
               "dexterity" => 1,
               "constitution" => 2,
               "intelligence" => -1,
               "wisdom" => 0,
               "charisma" => -1
             }
    end

    test "adds proficiency_bonus" do
      entity =
        entity_with(%{
          level: 5,
          stats: %{
            "strength" => 10,
            "dexterity" => 10,
            "constitution" => 10,
            "intelligence" => 10,
            "wisdom" => 10,
            "charisma" => 10
          }
        })

      hydrated = Stats.hydrate_entity(entity)
      assert hydrated.proficiency_bonus == 3
    end

    test "adds armor_class" do
      entity =
        entity_with(%{
          level: 1,
          stats: %{
            "strength" => 10,
            "dexterity" => 14,
            "constitution" => 10,
            "intelligence" => 10,
            "wisdom" => 10,
            "charisma" => 10,
            "equipped_armor" => %{"base_ac" => 16, "armor_category" => "heavy"}
          }
        })

      hydrated = Stats.hydrate_entity(entity)
      assert hydrated.armor_class == 16
    end
  end

  # --- helpers ---

  defp entity_with_stats(stats), do: entity_with(%{stats: stats})

  defp entity_with(overrides) do
    Map.merge(
      %{
        level: 1,
        class: "fighter",
        race: "human",
        stats: %{
          "strength" => 10,
          "dexterity" => 10,
          "constitution" => 10,
          "intelligence" => 10,
          "wisdom" => 10,
          "charisma" => 10
        }
      },
      overrides
    )
  end
end
