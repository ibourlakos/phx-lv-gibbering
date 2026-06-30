defmodule Gibbering.Monitoring.Stores.LocalTest do
  use ExUnit.Case, async: false

  alias Gibbering.Monitoring.Stores.Local
  alias Gibbering.Events.EventBatch
  alias Gibbering.Events.Engine.SessionEnded

  # Stores.Local uses named ETS tables. We start the GenServer directly here
  # to get fresh tables, then stop it after each test.
  setup do
    {:ok, pid} = GenServer.start_link(Local, [])

    on_exit(fn ->
      if Process.alive?(pid), do: GenServer.stop(pid)
    end)

    {:ok, pid: pid}
  end

  describe "record/3 and history/2" do
    test "records a sample and returns it via history" do
      :ok = Local.record(42, "memory_bytes", 8_192)
      history = Local.history(42, "memory_bytes")
      assert length(history) == 1
      {_dt, value} = hd(history)
      assert value == 8_192
    end

    test "history returns samples in chronological order" do
      :ok = Local.record(1, "queue_depth", 10)
      Process.sleep(2)
      :ok = Local.record(1, "queue_depth", 20)
      history = Local.history(1, "queue_depth")
      values = Enum.map(history, &elem(&1, 1))
      assert values == [10, 20]
    end

    test "history returns empty list for unknown campaign" do
      assert Local.history(9999, "memory_bytes") == []
    end

    test "history for one metric does not bleed into another" do
      :ok = Local.record(1, "memory_bytes", 100)
      :ok = Local.record(1, "queue_depth", 5)
      assert length(Local.history(1, "memory_bytes")) == 1
      assert length(Local.history(1, "queue_depth")) == 1
    end

    test "history for one campaign does not bleed into another" do
      :ok = Local.record(1, "memory_bytes", 100)
      :ok = Local.record(2, "memory_bytes", 200)
      [{_dt, v1}] = Local.history(1, "memory_bytes")
      [{_dt, v2}] = Local.history(2, "memory_bytes")
      assert v1 == 100
      assert v2 == 200
    end

    test "returns DateTime tuples" do
      :ok = Local.record(1, "memory_bytes", 512)
      [{dt, _v}] = Local.history(1, "memory_bytes")
      assert %DateTime{} = dt
    end
  end

  describe "scene_snapshot/1" do
    test "returns {\"?\", \"?\"} for unknown campaign" do
      assert Local.scene_snapshot(9999) == {"?", "?"}
    end

    test "returns entity count and phase after receiving an EventBatch", %{pid: pid} do
      state = %Gibbering.Engine.State{
        campaign_id: 42,
        entities: %{1 => %{}, 2 => %{}},
        phase: :in_combat,
        turn_order: [],
        active_index: 0
      }

      batch = %EventBatch{
        batch_id: "test",
        command: :end_turn,
        correlation_id: "corr",
        occurred_at: DateTime.utc_now(),
        state_snapshot: state,
        events: []
      }

      send(pid, batch)
      # allow handle_info to process
      :sys.get_state(pid)

      assert Local.scene_snapshot(42) == {2, :in_combat}
    end

    test "removes scene info when session ends", %{pid: pid} do
      state = %Gibbering.Engine.State{
        campaign_id: 7,
        entities: %{1 => %{}},
        phase: :exploration,
        turn_order: [],
        active_index: 0
      }

      seed_batch = %EventBatch{
        batch_id: "seed",
        command: :start_session,
        correlation_id: "c1",
        occurred_at: DateTime.utc_now(),
        state_snapshot: state,
        events: []
      }

      send(pid, seed_batch)
      :sys.get_state(pid)
      assert Local.scene_snapshot(7) == {1, :exploration}

      end_batch = %EventBatch{
        batch_id: "end",
        command: :end_session,
        correlation_id: "c2",
        occurred_at: DateTime.utc_now(),
        state_snapshot: state,
        events: [
          %SessionEnded{
            event_id: "e1",
            occurred_at: DateTime.utc_now(),
            correlation_id: "c2",
            causation_id: "c2",
            sequence_number: 0,
            event_type: :session_ended,
            schema_version: 1
          }
        ]
      }

      send(pid, end_batch)
      :sys.get_state(pid)
      assert Local.scene_snapshot(7) == {"?", "?"}
    end
  end
end
