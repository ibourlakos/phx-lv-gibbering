defmodule GibberingEngine.Monitoring.MetricsStoreTest do
  use ExUnit.Case, async: true

  alias GibberingEngine.Monitoring.MetricsStore
  alias GibberingEngine.Monitoring.Stores.NoOp

  describe "NoOp adapter" do
    test "record/3 returns :ok" do
      assert NoOp.record(1, "memory_bytes", 1024) == :ok
    end

    test "history/2 returns empty list" do
      assert NoOp.history(1, "memory_bytes") == []
    end
  end

  describe "MetricsStore delegation (test env uses NoOp)" do
    test "record/3 delegates to configured adapter" do
      assert MetricsStore.record(1, "memory_bytes", 1024) == :ok
    end

    test "history/2 delegates to configured adapter" do
      assert MetricsStore.history(1, "memory_bytes") == []
    end
  end
end
