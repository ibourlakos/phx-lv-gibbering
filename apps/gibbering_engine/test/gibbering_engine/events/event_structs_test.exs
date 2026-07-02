defmodule GibberingEngine.Events.EventStructsTest do
  use ExUnit.Case, async: true

  alias GibberingEngine.Events.{
    EntityMoved,
    TurnAdvanced,
    PhaseTransitioned,
    HPAdjusted,
    ResourceConsumed,
    ContainerOpened,
    RollRequired,
    SessionEnded,
    LogEntryRevealed,
    LogEntryHidden
  }

  @all_modules [
    EntityMoved,
    TurnAdvanced,
    PhaseTransitioned,
    HPAdjusted,
    ResourceConsumed,
    ContainerOpened,
    RollRequired,
    SessionEnded,
    LogEntryRevealed,
    LogEntryHidden
  ]

  describe "all engine event structs" do
    test "each module implements GibberingEngine.Events.Upcaster" do
      for mod <- @all_modules do
        behaviours =
          mod.module_info(:attributes) |> Keyword.get_values(:behaviour) |> List.flatten()

        assert GibberingEngine.Events.Upcaster in behaviours,
               "#{mod} does not implement GibberingEngine.Events.Upcaster"
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
        {EntityMoved, :entity_moved},
        {TurnAdvanced, :turn_advanced},
        {PhaseTransitioned, :phase_transitioned},
        {HPAdjusted, :hp_adjusted},
        {ResourceConsumed, :resource_consumed},
        {ContainerOpened, :container_opened},
        {RollRequired, :roll_required},
        {SessionEnded, :session_ended},
        {LogEntryRevealed, :log_entry_revealed},
        {LogEntryHidden, :log_entry_hidden}
      ]

      for {mod, atom} <- expected do
        assert struct(mod).event_type == atom,
               "#{mod}.event_type default != #{atom}"
      end
    end
  end

  describe "EntityMoved" do
    test "accepts all payload fields" do
      e = %EntityMoved{
        event_id: "uuid-1",
        occurred_at: ~U[2026-06-10 10:00:00Z],
        correlation_id: "corr-1",
        causation_id: "cause-1",
        sequence_number: 0,
        entity_id: "hero-1",
        entity_name: "Aragorn",
        from: {1, 1},
        to: {2, 2},
        cost_ft: 10
      }

      assert e.entity_name == "Aragorn"
      assert e.from == {1, 1}
      assert e.to == {2, 2}
      assert e.cost_ft == 10
    end
  end

  describe "TurnAdvanced" do
    test "carries both from- and to-entity fields" do
      e = %TurnAdvanced{
        event_id: "uuid-4",
        occurred_at: ~U[2026-06-10 10:00:00Z],
        correlation_id: "corr-2",
        causation_id: "cause-3",
        sequence_number: 0,
        from_entity_id: "hero-1",
        from_entity_name: "Aragorn",
        to_entity_id: "goblin-1",
        to_entity_name: "Goblin",
        round_number: 2
      }

      assert e.round_number == 2
      assert e.from_entity_name == "Aragorn"
    end
  end

  describe "HPAdjusted" do
    test "defaults to dm_only visibility" do
      assert struct(HPAdjusted).visibility == :dm_only
    end
  end

  describe "LogEntryRevealed / LogEntryHidden" do
    test "both default to dm_only visibility" do
      assert struct(LogEntryRevealed).visibility == :dm_only
      assert struct(LogEntryHidden).visibility == :dm_only
    end
  end
end
