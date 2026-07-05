defmodule GibberingTales.Rulesets.DnD5e.Stats do
  @moduledoc false

  @spellcasting_abilities %{
    "wizard" => "intelligence",
    "cleric" => "wisdom",
    "druid" => "wisdom",
    "bard" => "charisma",
    "sorcerer" => "charisma",
    "warlock" => "charisma",
    "paladin" => "charisma",
    "ranger" => "wisdom"
  }

  def ability_modifier(score), do: Integer.floor_div(score - 10, 2)

  def speed(entity), do: Map.get(entity, :speed, entity[:speed] || 30)

  @doc """
  Returns the entity's speed in feet for `mode`, or nil if the entity cannot use that mode.

  Walk always has a default of 30 ft. Climb, swim, and fly return nil when the
  corresponding stat key is absent (entity has no native ability for that mode).
  """
  def speed_for_mode(entity, "walk"), do: get_in(entity, [:stats, "speed"]) || 30
  def speed_for_mode(entity, "climb"), do: get_in(entity, [:stats, "climb_speed"])
  def speed_for_mode(entity, "swim"), do: get_in(entity, [:stats, "swim_speed"])
  def speed_for_mode(entity, "fly"), do: get_in(entity, [:stats, "fly_speed"])
  def speed_for_mode(_entity, _mode), do: nil

  def proficiency_bonus(level), do: div(level - 1, 4) + 2

  def armor_class(entity) do
    dex_mod = ability_modifier(stat(entity, "dexterity"))

    case get_in(entity, [:stats, "equipped_armor"]) do
      %{"base_ac" => base_ac, "armor_category" => category} when not is_nil(base_ac) ->
        case category do
          "heavy" -> base_ac
          "medium" -> base_ac + min(dex_mod, 2)
          _ -> base_ac + dex_mod
        end

      _ ->
        10 + dex_mod
    end
  end

  def attack_bonus(entity, :melee) do
    ability_modifier(stat(entity, "strength")) + proficiency_bonus(entity.level)
  end

  def attack_bonus(entity, :ranged) do
    ability_modifier(stat(entity, "dexterity")) + proficiency_bonus(entity.level)
  end

  def attack_bonus(entity, :spell) do
    spellcasting_modifier(entity) + proficiency_bonus(entity.level)
  end

  def spell_dc(entity) do
    8 + proficiency_bonus(entity.level) + spellcasting_modifier(entity)
  end

  def hydrate_entity(entity) do
    abilities = ~w(strength dexterity constitution intelligence wisdom charisma)

    ability_modifiers =
      Map.new(abilities, fn a -> {a, ability_modifier(stat(entity, a))} end)

    entity
    |> Map.put(:ability_modifiers, ability_modifiers)
    |> Map.put(:proficiency_bonus, proficiency_bonus(entity.level))
    |> Map.put(:armor_class, armor_class(entity))
  end

  defp spellcasting_modifier(entity) do
    ability = Map.get(@spellcasting_abilities, entity.class, "intelligence")
    ability_modifier(stat(entity, ability))
  end

  defp stat(entity, key), do: get_in(entity, [:stats, key]) || 10
end
