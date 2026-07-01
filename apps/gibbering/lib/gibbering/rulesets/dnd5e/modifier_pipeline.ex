defmodule Gibbering.Rulesets.DnD5e.ModifierPipeline do
  @moduledoc """
  Collects and applies `%RuleModifier{}` structs.

  `collect_modifiers/3` — gathers all modifiers relevant to an entity's
  action from class features, race traits, active condition effects, and
  equipped items (weapon/armour properties).

  `apply_modifiers/2` — folds collected effects onto a roll context in the
  canonical layering order: immunity → resistance → named bonuses (highest
  wins) → additive flat bonuses → dice modifiers → advantage/disadvantage.
  """

  alias Gibbering.Data.{Classes, Items, Races}
  alias GibberingEngine.RuleModifier
  alias Gibbering.Rulesets.DnD5e.{Condition, Predicate}

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
    modifiers_for_context(entity, eval_context)
    |> Enum.uniq_by(& &1.id)
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

  defp modifiers_for_context(entity, eval_context) do
    target = Map.get(eval_context, :target)
    target_conds = if target, do: Map.get(target, :conditions, []), else: []

    class_modifiers(Map.get(entity, :class, ""))
    |> Enum.concat(race_modifiers(Map.get(entity, :race, "")))
    |> Enum.concat(condition_modifiers(Map.get(entity, :conditions, [])))
    |> Enum.concat(condition_modifiers(target_conds))
    |> Enum.concat(equipped_item_modifiers(entity))
  end

  # Reads the entity's equipped weapon/armour slots, looks each key up in
  # Data.Items, and returns the item's derived modifiers. Unknown keys (e.g.
  # "no_armor") and empty slots contribute nothing. Trigger relevance is left to
  # the trigger filter in collect_modifiers/3.
  defp equipped_item_modifiers(entity) do
    ["equipped_weapon", "equipped_armor"]
    |> Enum.flat_map(fn slot ->
      with %{"key" => key} <- get_in(entity, [:stats, slot]),
           %{modifiers: mods} <- Items.get(key) do
        mods
      else
        _ -> []
      end
    end)
  end

  defp class_modifiers(class), do: Classes.modifiers(class)

  defp race_modifiers(race), do: Races.modifiers(race)

  defp condition_modifiers(conditions) do
    Enum.flat_map(conditions, fn key ->
      case Condition.get(key) do
        %Condition{modifiers: mods} -> mods
        nil -> []
      end
    end)
  end

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
      %RuleModifier{effect: {:set_speed, _}} -> true
      %RuleModifier{effect: {:set_all_speeds, _}} -> true
      %RuleModifier{effect: {:grant_speed, _, _}} -> true
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

        {:set_speed, n} ->
          Map.update(acc, :speed_override, n, &min(&1, n))

        {:set_all_speeds, n} ->
          acc
          |> Map.update(:speed_override, n, &min(&1, n))
          |> Map.update(:fly_speed_override, n, &min(&1, n))
          |> Map.update(:climb_speed_override, n, &min(&1, n))
          |> Map.update(:swim_speed_override, n, &min(&1, n))

        {:grant_speed, mode, value} ->
          Map.put(acc, {:speed_grant, mode}, value)
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
      {{:on_saving_throw, :any}, {:on_saving_throw, _}} -> true
      {{:on_saving_throw, ability}, {:on_saving_throw, ability}} -> true
      _ -> false
    end
  end
end
