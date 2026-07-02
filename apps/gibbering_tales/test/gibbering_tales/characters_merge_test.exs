defmodule GibberingTales.CharactersMergeTest do
  use ExUnit.Case, async: true

  alias GibberingTales.{Character, CampaignCharacter, Characters}

  # Elf wizard — race has dex+2, int+1 bonuses; background "sage" → arcana, history
  defp template(overrides \\ []) do
    struct(
      %Character{
        id: 1,
        user_id: 1,
        name: "Taevaleth",
        race: "elf",
        class: "wizard",
        level: 3,
        background: "sage",
        strength: 8,
        dexterity: 14,
        constitution: 12,
        intelligence: 16,
        wisdom: 13,
        charisma: 10,
        skill_proficiencies: ["arcana", "history"],
        saving_throw_proficiencies: ["intelligence", "wisdom"],
        tool_proficiencies: [],
        languages: ["common", "elvish"],
        spells_known: ["fire_bolt", "magic_missile"],
        life_events: [%{"text" => "Studied in the library"}],
        starting_items: [%{"key" => "quarterstaff"}],
        personality_traits: nil,
        ideals: nil,
        bonds: nil,
        flaws: nil,
        appearance: %{},
        inserted_at: nil,
        updated_at: nil
      },
      overrides
    )
  end

  defp campaign_character(overrides \\ []) do
    struct(
      %CampaignCharacter{
        id: 10,
        campaign_id: 100,
        character_id: 1,
        owner_id: 1,
        controller_id: 1,
        active: true,
        override_level: nil,
        override_ability_scores: nil,
        override_background_key: nil,
        override_starting_items: nil,
        override_bonus_proficiencies: nil,
        dm_life_events: nil,
        campaign_relations: nil,
        inserted_at: nil,
        updated_at: nil
      },
      overrides
    )
  end

  describe "merge/2 — all-nil overrides (pure template)" do
    test "uses template level" do
      result = Characters.merge(template(), campaign_character())
      assert result.level == 3
    end

    test "applies race stat bonuses on top of template ability scores" do
      result = Characters.merge(template(), campaign_character())
      # elf: dex+2, int+1
      assert result.stats["dexterity"] == 14 + 2
      assert result.stats["intelligence"] == 16 + 1
      assert result.stats["strength"] == 8
    end

    test "uses race speed" do
      result = Characters.merge(template(), campaign_character())
      # elf speed = 30
      assert result.stats["speed"] == 30
    end

    test "uses template background" do
      result = Characters.merge(template(), campaign_character())
      assert result.background == "sage"
    end

    test "merges and deduplicates skill proficiencies from template and background" do
      result = Characters.merge(template(), campaign_character())
      # template has ["arcana", "history"]; sage background also has ["arcana", "history"]
      assert Enum.sort(result.skill_proficiencies) == ["arcana", "history"]
    end

    test "preserves template life_events with no DM additions" do
      result = Characters.merge(template(), campaign_character())
      assert result.life_events == [%{"text" => "Studied in the library"}]
    end

    test "uses template starting_items" do
      result = Characters.merge(template(), campaign_character())
      assert result.starting_items == [%{"key" => "quarterstaff"}]
    end

    test "sets controller_id from campaign_character" do
      result = Characters.merge(template(), campaign_character(controller_id: 42))
      assert result.controller_id == 42
    end

    test "carries identity fields from template" do
      result = Characters.merge(template(), campaign_character())
      assert result.name == "Taevaleth"
      assert result.race == "elf"
      assert result.class == "wizard"
      assert result.type == "hero"
      assert result.character_id == 1
      assert result.campaign_character_id == 10
    end
  end

  describe "merge/2 — full overrides (all DM values win)" do
    test "override_level replaces template level" do
      result = Characters.merge(template(), campaign_character(override_level: 10))
      assert result.level == 10
    end

    test "override_ability_scores replaces per-key values before race bonuses" do
      result =
        Characters.merge(
          template(),
          campaign_character(override_ability_scores: %{"strength" => 18, "dexterity" => 10})
        )

      # strength fully overridden; elf dex bonus still applies on top of the override
      assert result.stats["strength"] == 18
      assert result.stats["dexterity"] == 10 + 2
      # unchanged scores still get race bonus
      assert result.stats["intelligence"] == 16 + 1
    end

    test "override_background_key changes proficiency source" do
      # soldier background has "athletics", "intimidation"
      result =
        Characters.merge(
          template(),
          campaign_character(override_background_key: "soldier")
        )

      assert result.background == "soldier"
      assert "athletics" in result.skill_proficiencies
      assert "intimidation" in result.skill_proficiencies
    end

    test "override_starting_items replaces template items" do
      new_items = [%{"key" => "longsword"}, %{"key" => "shield"}]

      result =
        Characters.merge(template(), campaign_character(override_starting_items: new_items))

      assert result.starting_items == new_items
    end

    test "override_bonus_proficiencies are appended and deduplicated" do
      result =
        Characters.merge(
          template(),
          campaign_character(override_bonus_proficiencies: ["perception", "arcana"])
        )

      assert "perception" in result.skill_proficiencies
      assert Enum.count(result.skill_proficiencies, &(&1 == "arcana")) == 1
    end

    test "dm_life_events are appended after template events" do
      dm_events = [%{"text" => "Survived the siege"}]

      result =
        Characters.merge(template(), campaign_character(dm_life_events: dm_events))

      assert result.life_events == [
               %{"text" => "Studied in the library"},
               %{"text" => "Survived the siege"}
             ]
    end
  end

  describe "merge/2 — partial overrides" do
    test "nil override fields fall back to template" do
      result =
        Characters.merge(
          template(),
          campaign_character(override_level: 7, override_ability_scores: nil)
        )

      assert result.level == 7
      # ability scores from template + race bonuses (no override)
      assert result.stats["intelligence"] == 16 + 1
    end
  end
end
