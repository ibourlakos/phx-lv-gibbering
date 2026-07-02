defmodule GibberingEngine.Events.DecoderTest do
  use ExUnit.Case, async: true

  alias GibberingEngine.Events.Decoder
  alias GibberingEngine.Events.{TurnAdvanced, SessionEnded, EntityMoved}

  defp entity_moved_raw do
    %{
      "event_id" => "uuid-em-1",
      "event_type" => "entity_moved",
      "schema_version" => 1,
      "occurred_at" => ~U[2026-06-10 10:00:00Z],
      "correlation_id" => "corr-1",
      "causation_id" => "cause-1",
      "sequence_number" => 0,
      "entity_id" => "hero-1",
      "entity_name" => "Aragorn",
      "from" => {0, 0},
      "to" => {1, 1},
      "cost_ft" => 5
    }
  end

  describe "decode/2 at current version (v1)" do
    test "returns {:ok, struct} for a valid raw map" do
      assert {:ok, %EntityMoved{} = e} = Decoder.decode(EntityMoved, entity_moved_raw())
      assert e.entity_name == "Aragorn"
      assert e.cost_ft == 5
      assert e.schema_version == 1
    end

    test "schema_version in result is always current_version" do
      {:ok, e} = Decoder.decode(EntityMoved, entity_moved_raw())
      assert e.schema_version == EntityMoved.current_version()
    end

    test "defaults schema_version to 1 when absent from raw map" do
      raw = Map.delete(entity_moved_raw(), "schema_version")
      assert {:ok, %EntityMoved{schema_version: 1}} = Decoder.decode(EntityMoved, raw)
    end

    test "decodes TurnAdvanced" do
      raw = %{
        "event_id" => "uuid-ta-1",
        "event_type" => "turn_advanced",
        "schema_version" => 1,
        "occurred_at" => ~U[2026-06-10 10:00:00Z],
        "correlation_id" => "corr-2",
        "causation_id" => "cause-2",
        "sequence_number" => 0,
        "from_entity_id" => "hero-1",
        "from_entity_name" => "Aragorn",
        "to_entity_id" => "goblin-1",
        "to_entity_name" => "Goblin",
        "round_number" => 3
      }

      assert {:ok, %TurnAdvanced{round_number: 3, from_entity_name: "Aragorn"}} =
               Decoder.decode(TurnAdvanced, raw)
    end

    test "decodes SessionEnded" do
      raw = %{
        "event_id" => "uuid-se-1",
        "event_type" => "session_ended",
        "schema_version" => 1,
        "occurred_at" => ~U[2026-06-10 10:00:00Z],
        "correlation_id" => "corr-3",
        "causation_id" => "cause-3",
        "sequence_number" => 0,
        "campaign_id" => "camp-1"
      }

      assert {:ok, %SessionEnded{campaign_id: "camp-1"}} = Decoder.decode(SessionEnded, raw)
    end
  end

  describe "decode/2 error cases" do
    test "returns {:error, {:schema_version_too_new, ...}} when stored version exceeds current" do
      raw = Map.put(entity_moved_raw(), "schema_version", 99)
      assert {:error, {:schema_version_too_new, 99, 1}} = Decoder.decode(EntityMoved, raw)
    end

    test "returns {:error, _} for unrecognised string key" do
      raw = Map.put(entity_moved_raw(), "nonexistent_atom_xyzzy", "value")
      assert {:error, _} = Decoder.decode(EntityMoved, raw)
    end
  end
end
