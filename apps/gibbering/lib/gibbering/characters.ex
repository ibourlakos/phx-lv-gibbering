defmodule Gibbering.Characters do
  @moduledoc "Context for player-owned character templates, including campaign-scoped merge logic."

  import Ecto.Query

  alias Gibbering.{Repo, Character, CampaignCharacter}
  alias Gibbering.Data.{Races, Backgrounds}

  def list_for_user(user_id) do
    Character
    |> where(user_id: ^user_id)
    |> order_by(:name)
    |> Repo.all()
  end

  def get_character!(user_id, id) do
    Character
    |> where(user_id: ^user_id, id: ^id)
    |> Repo.one!()
  end

  def create_character(user_id, attrs) do
    %Character{user_id: user_id}
    |> Character.changeset(attrs)
    |> Repo.insert()
  end

  def update_character(%Character{} = character, attrs) do
    character
    |> Character.changeset(attrs)
    |> Repo.update()
  end

  def delete_character(user_id, id) do
    character = get_character!(user_id, id)
    Repo.delete(character)
  end

  @doc """
  Merges a `%Character{}` template with `%CampaignCharacter{}` overrides into
  a resolved entity map ready for scene hydration.

  Override fields win over template values; a `nil` override falls back to the
  template. Race stat bonuses are applied after the score source is resolved.
  """
  def merge(%Character{} = t, %CampaignCharacter{} = cc) do
    level = cc.override_level || t.level
    background_key = cc.override_background_key || t.background

    base_scores = %{
      "strength" => t.strength,
      "dexterity" => t.dexterity,
      "constitution" => t.constitution,
      "intelligence" => t.intelligence,
      "wisdom" => t.wisdom,
      "charisma" => t.charisma
    }

    scores =
      if cc.override_ability_scores do
        Map.merge(base_scores, cc.override_ability_scores)
      else
        base_scores
      end

    race_data = Races.seed_data()[t.race] || %{}
    race_bonuses = Map.get(race_data, :stat_bonuses, %{})
    race_speed = Map.get(race_data, :speed, 30)

    scores =
      Map.new(scores, fn {ability, value} ->
        {ability, value + Map.get(race_bonuses, ability, 0)}
      end)

    background_data = Backgrounds.get(background_key) || %{}
    background_profs = Map.get(background_data, :skill_proficiencies, [])
    bonus_profs = cc.override_bonus_proficiencies || []

    skill_proficiencies =
      (t.skill_proficiencies ++ background_profs ++ bonus_profs)
      |> Enum.uniq()

    starting_items = cc.override_starting_items || t.starting_items
    dm_life_events = cc.dm_life_events || []
    life_events = t.life_events ++ dm_life_events

    %{
      character_id: t.id,
      campaign_character_id: cc.id,
      controller_id: cc.controller_id || cc.owner_id,
      name: t.name,
      type: "hero",
      race: t.race,
      class: t.class,
      level: level,
      background: background_key,
      stats: Map.put(scores, "speed", race_speed),
      skill_proficiencies: skill_proficiencies,
      saving_throw_proficiencies: t.saving_throw_proficiencies,
      spells_known: t.spells_known,
      starting_items: starting_items,
      life_events: life_events,
      tags: []
    }
  end
end
