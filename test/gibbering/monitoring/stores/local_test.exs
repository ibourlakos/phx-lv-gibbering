defmodule Gibbering.Monitoring.Stores.LocalTest do
  use ExUnit.Case, async: false

  alias Gibbering.Monitoring.Stores.Local

  # Stores.Local uses a named ETS table. We start the GenServer directly here
  # to get a fresh ETS table, then stop it after each test.
  setup do
    {:ok, pid} = GenServer.start_link(Local, [])

    on_exit(fn ->
      if Process.alive?(pid), do: GenServer.stop(pid)
    end)

    :ok
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
end
