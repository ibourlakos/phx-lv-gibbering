defmodule GibberingTales.CharactersFixtures do
  alias GibberingTales.Characters

  def valid_character_attrs(overrides \\ %{}) do
    Map.merge(
      %{
        "name" => "Taevaleth",
        "race" => "elf",
        "class" => "wizard",
        "level" => 1,
        "alignment" => "neutral_good",
        "background" => "sage",
        "strength" => 8,
        "dexterity" => 14,
        "constitution" => 12,
        "intelligence" => 16,
        "wisdom" => 13,
        "charisma" => 10,
        "skill_proficiencies" => ["arcana", "history"],
        "saving_throw_proficiencies" => ["intelligence", "wisdom"],
        "tool_proficiencies" => [],
        "languages" => ["common", "elvish"],
        "spells_known" => ["fire_bolt", "mage_hand"],
        "personality_traits" => "I use big words to seem smarter.",
        "ideals" => "Knowledge is the path to enlightenment.",
        "bonds" => "I protect the library where I learned to read.",
        "flaws" => "I overlook obvious solutions in favour of complex ones.",
        "appearance" => %{
          "body_type" => "light",
          "hair_style" => "long",
          "hair_color" => "silver",
          "skin_tone" => "pale",
          "eye_color" => "violet"
        },
        "life_events" => [],
        "starting_items" => []
      },
      overrides
    )
  end

  def create_character(user, overrides \\ %{}) do
    {:ok, character} =
      Characters.create_character(user.id, valid_character_attrs(overrides))

    character
  end
end
