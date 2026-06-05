defmodule Gibbering.Rulesets.DnD5e do
  @moduledoc """
  D&D 5e SRD ruleset implementation.

  This is the primary ruleset for The Gibbering Engine. All DnD5e subsystems
  (Stats, Spell, RuleModifier, Condition) live under `Gibbering.Rulesets.DnD5e.*`.
  """

  @behaviour Gibbering.Ruleset

  alias Gibbering.Rulesets.DnD5e.Stats

  @impl Gibbering.Ruleset
  def collect_modifiers(_entity, _action, _state), do: []

  @impl Gibbering.Ruleset
  def initial_resources(entity) do
    class = Map.get(entity, :class, entity[:class] || "fighter")

    case class do
      "wizard" -> %{spell_slots: %{1 => 2, 2 => 0, 3 => 0, 4 => 0, 5 => 0}}
      "cleric" -> %{spell_slots: %{1 => 2, 2 => 0, 3 => 0, 4 => 0, 5 => 0}}
      "sorcerer" -> %{spell_slots: %{1 => 2, 2 => 0, 3 => 0, 4 => 0, 5 => 0}}
      "bard" -> %{spell_slots: %{1 => 2, 2 => 0, 3 => 0, 4 => 0, 5 => 0}}
      "druid" -> %{spell_slots: %{1 => 2, 2 => 0, 3 => 0, 4 => 0, 5 => 0}}
      "warlock" -> %{pact_slots: 1}
      "paladin" -> %{spell_slots: %{1 => 0}}
      "ranger" -> %{spell_slots: %{1 => 0}}
      _ -> %{}
    end
  end

  @impl Gibbering.Ruleset
  def initial_action_economy(entity) do
    speed = Stats.speed(entity)

    %{
      action: :available,
      bonus_action: :available,
      reaction: :available,
      movement_remaining: speed
    }
  end

  @impl Gibbering.Ruleset
  def advance_turn(entity) do
    speed = Stats.speed(entity)

    Map.put(entity, :action_economy, %{
      action: :available,
      bonus_action: :available,
      reaction: :available,
      movement_remaining: speed
    })
  end
end
