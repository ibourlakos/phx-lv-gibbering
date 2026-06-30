defmodule Gibbering.Events.DnD5e.EventStructsTest do
  use ExUnit.Case, async: true

  alias Gibbering.Events.DnD5e.{
    AttackResolved,
    DamageDealt,
    SpellCast,
    ConditionApplied,
    ConditionRemoved,
    ItemEquipped,
    ItemTaken
  }

  @all_modules [
    AttackResolved,
    DamageDealt,
    SpellCast,
    ConditionApplied,
    ConditionRemoved,
    ItemEquipped,
    ItemTaken
  ]

  describe "all DnD5e event structs" do
    test "each module implements Gibbering.Events.Upcaster" do
      for mod <- @all_modules do
        behaviours =
          mod.module_info(:attributes) |> Keyword.get_values(:behaviour) |> List.flatten()

        assert Gibbering.Events.Upcaster in behaviours,
               "#{mod} does not implement Gibbering.Events.Upcaster"
      end
    end

    test "each module exposes current_version/0 returning 1" do
      for mod <- @all_modules do
        assert mod.current_version() == 1, "#{mod}.current_version() != 1"
      end
    end

    test "each module's upcast/2 is an identity function at v1" do
      raw = %{"event_id" => "abc", "schema_version" => 1}

      for mod <- @all_modules do
        assert mod.upcast(1, raw) == raw, "#{mod}.upcast(1, map) is not identity"
      end
    end

    test "schema_version defaults to 1 on all structs" do
      for mod <- @all_modules do
        s = struct(mod)
        assert s.schema_version == 1, "#{mod} schema_version default != 1"
      end
    end

    test "event_type is set to the correct default atom on all structs" do
      expected = [
        {AttackResolved, :attack_resolved},
        {DamageDealt, :damage_dealt},
        {SpellCast, :spell_cast},
        {ConditionApplied, :condition_applied},
        {ConditionRemoved, :condition_removed},
        {ItemEquipped, :item_equipped},
        {ItemTaken, :item_taken}
      ]

      for {mod, atom} <- expected do
        assert struct(mod).event_type == atom,
               "#{mod}.event_type default != #{atom}"
      end
    end
  end

  describe "AttackResolved" do
    test "accepts hit? field" do
      e = %AttackResolved{
        event_id: "uuid-2",
        occurred_at: ~U[2026-06-10 10:00:00Z],
        correlation_id: "corr-1",
        causation_id: "cause-1",
        sequence_number: 0,
        attacker_id: "hero-1",
        attacker_name: "Aragorn",
        target_id: "goblin-1",
        target_name: "Goblin",
        roll: 15,
        hit?: true
      }

      assert e.hit? == true
      assert e.roll == 15
    end
  end

  describe "DamageDealt" do
    test "includes new_hp as post-damage authoritative value" do
      e = %DamageDealt{
        event_id: "uuid-3",
        occurred_at: ~U[2026-06-10 10:00:00Z],
        correlation_id: "corr-1",
        causation_id: "cause-2",
        sequence_number: 1,
        target_id: "goblin-1",
        target_name: "Goblin",
        amount: 8,
        damage_type: :slashing,
        new_hp: 4
      }

      assert e.amount == 8
      assert e.new_hp == 4
    end
  end
end
