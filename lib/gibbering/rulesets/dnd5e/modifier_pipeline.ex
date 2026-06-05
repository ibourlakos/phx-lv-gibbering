defmodule Gibbering.Rulesets.DnD5e.ModifierPipeline do
  @moduledoc """
  Collects and applies `%RuleModifier{}` structs.

  `collect_modifiers/3` — gathers all modifiers relevant to an entity's
  action from class features, race traits, and active condition effects.

  `apply_modifiers/2` — folds collected effects onto a roll context in the
  canonical layering order: immunity → resistance → named bonuses (highest
  wins) → additive flat bonuses → dice modifiers → advantage/disadvantage.
  """

  alias Gibbering.Rulesets.DnD5e.{Predicate, RuleModifier}

  # ---------------------------------------------------------------------------
  # collect_modifiers/3
  # ---------------------------------------------------------------------------

  @doc """
  Returns all `%RuleModifier{}` structs whose trigger matches `trigger` and
  whose predicate evaluates to `true` in the given `eval_context`.

  `eval_context` must conform to the shape in docs/predicate-vocabulary.md:
    %{entity: entity_map, target: entity_map | nil,
      scene: scene_context, resolution: resolution_context | nil}
  """
  def collect_modifiers(entity, trigger, eval_context) do
    modifiers_for_entity(entity)
    |> Enum.filter(fn %RuleModifier{trigger: t, predicate: pred, min_level: min_lvl} ->
      trigger_matches?(t, trigger) and
        Map.get(entity, :level, 1) >= min_lvl and
        Predicate.eval(pred, eval_context)
    end)
  end

  # ---------------------------------------------------------------------------
  # apply_modifiers/2
  # ---------------------------------------------------------------------------

  @doc """
  Folds a list of `%RuleModifier{}` effects onto a roll context map.

  Returns an updated roll context. The layering order matches 5e rules:
  immunity → resistance/vulnerability → named bonuses (highest wins) →
  additive flat bonuses → dice modifiers → advantage/disadvantage collapse.

  The roll context is a plain map the caller populates. Recognised keys:
    :damage_total, :attack_bonus, :save_bonus, :advantage_count,
    :disadvantage_count, :damage_dice, :immune, :resistant, :damage_multiplier
  """
  def apply_modifiers(roll_context, modifiers) do
    roll_context
    |> apply_immunity(modifiers)
    |> apply_resistance(modifiers)
    |> apply_named_bonuses(modifiers)
    |> apply_additive_bonuses(modifiers)
    |> apply_dice_modifiers(modifiers)
    |> apply_advantage_disadvantage(modifiers)
  end

  # ---------------------------------------------------------------------------
  # Private — modifier source registry
  # ---------------------------------------------------------------------------

  defp modifiers_for_entity(entity) do
    class_modifiers(Map.get(entity, :class, ""))
    |> Enum.concat(race_modifiers(Map.get(entity, :race, "")))
    |> Enum.concat(condition_modifiers(Map.get(entity, :conditions, [])))
  end

  # Class feature modifiers — stubs; real modifiers wired in #47
  defp class_modifiers(_class), do: []

  # Race trait modifiers — stubs; real modifiers wired in #47
  defp race_modifiers(_race), do: []

  # Active condition modifiers — stubs; wired when #42 (Condition struct) lands
  defp condition_modifiers(_conditions), do: []

  # ---------------------------------------------------------------------------
  # Private — effect application layers
  # ---------------------------------------------------------------------------

  defp apply_immunity(ctx, modifiers) do
    immune_types =
      modifiers
      |> Enum.filter(&match?(%RuleModifier{effect: {:grant_immunity, _}}, &1))
      |> Enum.map(fn %RuleModifier{effect: {:grant_immunity, type}} -> type end)

    if immune_types == [] do
      ctx
    else
      Map.update(ctx, :immune, MapSet.new(immune_types), fn existing ->
        Enum.reduce(immune_types, existing, &MapSet.put(&2, &1))
      end)
      |> Map.put(:damage_multiplier, 0)
    end
  end

  defp apply_resistance(ctx, modifiers) do
    if Map.get(ctx, :damage_multiplier, 1) == 0 do
      ctx
    else
      resistant_types =
        modifiers
        |> Enum.filter(&match?(%RuleModifier{effect: {:grant_resistance, _}}, &1))
        |> Enum.map(fn %RuleModifier{effect: {:grant_resistance, type}} -> type end)

      if resistant_types == [] do
        ctx
      else
        Map.update(ctx, :resistant, MapSet.new(resistant_types), fn existing ->
          Enum.reduce(resistant_types, existing, &MapSet.put(&2, &1))
        end)
        |> Map.update(:damage_multiplier, 0.5, &min(&1, 0.5))
      end
    end
  end

  defp apply_named_bonuses(ctx, modifiers) do
    named =
      modifiers
      |> Enum.filter(fn
        %RuleModifier{stacking: :named_bonus, effect: {:add_bonus, _, _}} -> true
        _ -> false
      end)

    named
    |> Enum.group_by(fn %RuleModifier{id: id} -> id end)
    |> Enum.reduce(ctx, fn {_id, group}, acc ->
      best = Enum.max_by(group, fn %RuleModifier{effect: {:add_bonus, _, v}} -> v end)
      apply_bonus_effect(acc, best.effect)
    end)
  end

  defp apply_additive_bonuses(ctx, modifiers) do
    modifiers
    |> Enum.filter(fn
      %RuleModifier{stacking: :additive, effect: {:add_bonus, _, _}} -> true
      _ -> false
    end)
    |> Enum.reduce(ctx, fn %RuleModifier{effect: effect}, acc ->
      apply_bonus_effect(acc, effect)
    end)
  end

  defp apply_dice_modifiers(ctx, modifiers) do
    modifiers
    |> Enum.filter(fn
      %RuleModifier{effect: {:add_damage_dice, _, _}} -> true
      %RuleModifier{effect: {:add_to_roll, _}} -> true
      %RuleModifier{effect: {:force_critical_hit}} -> true
      _ -> false
    end)
    |> Enum.reduce(ctx, fn %RuleModifier{effect: effect}, acc ->
      case effect do
        {:add_damage_dice, dice, _name_key} ->
          Map.update(acc, :damage_dice, [dice], &[dice | &1])

        {:add_to_roll, dice} ->
          Map.update(acc, :roll_dice, [dice], &[dice | &1])

        {:force_critical_hit} ->
          Map.put(acc, :is_critical, true)
      end
    end)
  end

  defp apply_advantage_disadvantage(ctx, modifiers) do
    adv_count =
      Enum.count(modifiers, &match?(%RuleModifier{effect: {:grant_advantage, _}}, &1))

    dis_count =
      Enum.count(modifiers, &match?(%RuleModifier{effect: {:impose_disadvantage, _}}, &1))

    ctx
    |> then(fn c ->
      if adv_count > 0, do: Map.update(c, :advantage_count, adv_count, &(&1 + adv_count)), else: c
    end)
    |> then(fn c ->
      if dis_count > 0,
        do: Map.update(c, :disadvantage_count, dis_count, &(&1 + dis_count)),
        else: c
    end)
  end

  defp apply_bonus_effect(ctx, {:add_bonus, :damage, value}),
    do: Map.update(ctx, :damage_total, value, &(&1 + value))

  defp apply_bonus_effect(ctx, {:add_bonus, :attack, value}),
    do: Map.update(ctx, :attack_bonus, value, &(&1 + value))

  defp apply_bonus_effect(ctx, {:add_bonus, :save, value}),
    do: Map.update(ctx, :save_bonus, value, &(&1 + value))

  defp apply_bonus_effect(ctx, _), do: ctx

  defp trigger_matches?(modifier_trigger, action_trigger) do
    case {modifier_trigger, action_trigger} do
      {:passive, _} -> true
      {t, t} -> true
      {{:on_attack, :any}, {:on_attack, _}} -> true
      {{:on_attack, type}, {:on_attack, type}} -> true
      {{:on_damage_received, :any}, {:on_damage_received, _}} -> true
      {{:on_damage_received, type}, {:on_damage_received, type}} -> true
      _ -> false
    end
  end
end
