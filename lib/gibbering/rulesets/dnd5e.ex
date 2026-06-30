defmodule Gibbering.Rulesets.DnD5e do
  @moduledoc """
  D&D 5e SRD ruleset implementation.

  This is the primary ruleset for The Gibbering Engine. All DnD5e subsystems
  (Stats, Spell, RuleModifier, Condition) live under `Gibbering.Rulesets.DnD5e.*`.
  """

  @behaviour Gibbering.Ruleset

  alias Gibbering.Engine.RuleModifier
  alias Gibbering.Rulesets.DnD5e.{ModifierPipeline, Stats}

  # SRD spell slot table for full casters (Wizard, Cleric, Sorcerer, Bard, Druid).
  # Keys are character level; values are slot counts per spell level.
  @full_caster_slots %{
    1 => %{1 => 2},
    2 => %{1 => 3},
    3 => %{1 => 4, 2 => 2},
    4 => %{1 => 4, 2 => 3},
    5 => %{1 => 4, 2 => 3, 3 => 2},
    6 => %{1 => 4, 2 => 3, 3 => 3},
    7 => %{1 => 4, 2 => 3, 3 => 3, 4 => 1},
    8 => %{1 => 4, 2 => 3, 3 => 3, 4 => 2},
    9 => %{1 => 4, 2 => 3, 3 => 3, 4 => 3, 5 => 1},
    10 => %{1 => 4, 2 => 3, 3 => 3, 4 => 3, 5 => 2},
    11 => %{1 => 4, 2 => 3, 3 => 3, 4 => 3, 5 => 2, 6 => 1},
    12 => %{1 => 4, 2 => 3, 3 => 3, 4 => 3, 5 => 2, 6 => 1},
    13 => %{1 => 4, 2 => 3, 3 => 3, 4 => 3, 5 => 2, 6 => 1, 7 => 1},
    14 => %{1 => 4, 2 => 3, 3 => 3, 4 => 3, 5 => 2, 6 => 1, 7 => 1},
    15 => %{1 => 4, 2 => 3, 3 => 3, 4 => 3, 5 => 2, 6 => 1, 7 => 1, 8 => 1},
    16 => %{1 => 4, 2 => 3, 3 => 3, 4 => 3, 5 => 2, 6 => 1, 7 => 1, 8 => 1},
    17 => %{1 => 4, 2 => 3, 3 => 3, 4 => 3, 5 => 2, 6 => 1, 7 => 1, 8 => 1, 9 => 1},
    18 => %{1 => 4, 2 => 3, 3 => 3, 4 => 3, 5 => 3, 6 => 1, 7 => 1, 8 => 1, 9 => 1},
    19 => %{1 => 4, 2 => 3, 3 => 3, 4 => 3, 5 => 3, 6 => 2, 7 => 1, 8 => 1, 9 => 1},
    20 => %{1 => 4, 2 => 3, 3 => 3, 4 => 3, 5 => 3, 6 => 2, 7 => 2, 8 => 1, 9 => 1}
  }

  # SRD spell slot table for half-casters (Paladin, Ranger).
  # Spell progression begins at character level 2.
  @half_caster_slots %{
    1 => %{},
    2 => %{1 => 2},
    3 => %{1 => 3},
    4 => %{1 => 3},
    5 => %{1 => 4, 2 => 2},
    6 => %{1 => 4, 2 => 2},
    7 => %{1 => 4, 2 => 3},
    8 => %{1 => 4, 2 => 3},
    9 => %{1 => 4, 2 => 3, 3 => 2},
    10 => %{1 => 4, 2 => 3, 3 => 2},
    11 => %{1 => 4, 2 => 3, 3 => 3},
    12 => %{1 => 4, 2 => 3, 3 => 3},
    13 => %{1 => 4, 2 => 3, 3 => 3, 4 => 1},
    14 => %{1 => 4, 2 => 3, 3 => 3, 4 => 1},
    15 => %{1 => 4, 2 => 3, 3 => 3, 4 => 2},
    16 => %{1 => 4, 2 => 3, 3 => 3, 4 => 2},
    17 => %{1 => 4, 2 => 3, 3 => 3, 4 => 3, 5 => 1},
    18 => %{1 => 4, 2 => 3, 3 => 3, 4 => 3, 5 => 1},
    19 => %{1 => 4, 2 => 3, 3 => 3, 4 => 3, 5 => 2},
    20 => %{1 => 4, 2 => 3, 3 => 3, 4 => 3, 5 => 2}
  }

  @impl Gibbering.Ruleset
  def collect_modifiers(entity, trigger, eval_context),
    do: ModifierPipeline.collect_modifiers(entity, trigger, eval_context)

  @impl Gibbering.Ruleset
  def initial_resources(entity) do
    class = Map.get(entity, :class, "fighter")
    level = Map.get(entity, :level, 1) |> max(1) |> min(20)

    case class do
      c when c in ~w(wizard cleric sorcerer bard druid) ->
        %{spell_slots: Map.get(@full_caster_slots, level, %{1 => 2})}

      c when c in ~w(paladin ranger) ->
        %{spell_slots: Map.get(@half_caster_slots, level, %{})}

      "warlock" ->
        {pact_level, count} = warlock_pact_slots(level)
        %{pact_slots: count, pact_slot_level: pact_level}

      "barbarian" ->
        %{rage_charges: barbarian_rage_charges(level)}

      "fighter" ->
        resources = %{second_wind: 1}

        if level >= 2,
          do: Map.put(resources, :action_surge, action_surge_charges(level)),
          else: resources

      _ ->
        %{}
    end
  end

  @impl Gibbering.Ruleset
  def initial_action_economy(entity) do
    speed = Stats.speed(entity)
    movement_remaining = apply_passive_speed(entity, speed)

    %{
      action: :available,
      bonus_action: :available,
      reaction: :available,
      movement_remaining: movement_remaining
    }
  end

  @impl Gibbering.Ruleset
  def advance_turn(entity) do
    speed = Stats.speed(entity)
    movement_remaining = apply_passive_speed(entity, speed)

    Map.put(entity, :action_economy, %{
      action: :available,
      bonus_action: :available,
      reaction: :available,
      movement_remaining: movement_remaining
    })
  end

  @impl Gibbering.Ruleset
  def short_rest_entity(entity) do
    class = Map.get(entity, :class, "fighter")
    level = Map.get(entity, :level, 1) |> max(1) |> min(20)

    case class do
      "warlock" ->
        {pact_level, count} = warlock_pact_slots(level)

        Map.update(entity, :resources, %{}, fn r ->
          r |> Map.put(:pact_slots, count) |> Map.put(:pact_slot_level, pact_level)
        end)

      "fighter" ->
        Map.update(entity, :resources, %{}, fn r ->
          resources = Map.put(r, :second_wind, 1)

          if level >= 2,
            do: Map.put(resources, :action_surge, action_surge_charges(level)),
            else: resources
        end)

      _ ->
        entity
    end
  end

  @impl Gibbering.Ruleset
  def long_rest_entity(entity) do
    Map.put(entity, :resources, initial_resources(entity))
  end

  @impl Gibbering.Ruleset
  def action_buttons(entity, _state) do
    movement_remaining = get_in(entity, [:action_economy, :movement_remaining]) || 0

    move_btn = %{
      event: "activate_move",
      value: %{},
      label: "Move",
      sublabel: "#{movement_remaining} ft",
      disabled: movement_remaining == 0
    }

    spells = get_in(entity, [:stats, "spells"]) || []

    spell_btns =
      Enum.map(spells, fn spell_key ->
        spell = Gibbering.Data.Spells.get(spell_key)

        %{
          event: "select_spell",
          value: %{"key" => spell_key},
          label: if(spell, do: spell.name, else: humanize_key(spell_key)),
          sublabel: spell_level_label(spell),
          disabled: false
        }
      end)

    [move_btn | spell_btns]
  end

  @impl Gibbering.Ruleset
  def available_conditions do
    Gibbering.Rulesets.DnD5e.Condition.all()
    |> Enum.map(fn {id, defn} -> {id, defn.name} end)
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  defp humanize_key(key) do
    key
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  defp spell_level_label(nil), do: ""
  defp spell_level_label(%{level: 0}), do: "cantrip"
  defp spell_level_label(%{level: n}), do: "L#{n}"

  defp warlock_pact_slots(level) do
    cond do
      level >= 17 -> {5, 4}
      level >= 11 -> {5, 3}
      level >= 9 -> {5, 2}
      level >= 7 -> {4, 2}
      level >= 5 -> {3, 2}
      level >= 3 -> {2, 2}
      true -> {1, 1}
    end
  end

  defp barbarian_rage_charges(level) do
    cond do
      level >= 20 -> :unlimited
      level >= 17 -> 6
      level >= 12 -> 5
      level >= 6 -> 4
      level >= 3 -> 3
      true -> 2
    end
  end

  defp action_surge_charges(level), do: if(level >= 17, do: 2, else: 1)

  defp apply_passive_speed(entity, base_speed) do
    eval_ctx = %{entity: entity, target: nil, scene: %{active_effects: []}, resolution: nil}

    ModifierPipeline.collect_modifiers(entity, :passive, eval_ctx)
    |> Enum.reduce(base_speed, fn
      %RuleModifier{effect: {:set_speed, n}}, acc -> min(acc, n)
      %RuleModifier{effect: {:set_all_speeds, n}}, acc -> min(acc, n)
      _, acc -> acc
    end)
  end
end
