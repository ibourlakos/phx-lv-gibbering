defmodule GibberingEngine.EventBus.LocalTest do
  use ExUnit.Case, async: true

  alias GibberingEngine.EventBus.Local
  alias GibberingEngine.Events.EventBatch

  setup do
    start_supervised!(Local)
    :ok
  end

  describe "subscribe/1 + broadcast/2" do
    test "subscribed process receives broadcast message" do
      Local.subscribe("test:topic")
      Local.broadcast("test:topic", :hello)
      assert_receive :hello
    end

    test "non-subscribed process does not receive broadcast" do
      Local.broadcast("test:topic", :hello)
      refute_receive :hello, 50
    end

    test "broadcast delivers to all subscribers on a topic" do
      parent = self()

      child =
        spawn(fn ->
          Local.subscribe("test:multi")
          send(parent, :child_ready)

          receive do
            msg -> send(parent, {:child_got, msg})
          end
        end)

      assert_receive :child_ready

      Local.subscribe("test:multi")
      Local.broadcast("test:multi", :ping)

      assert_receive :ping
      assert_receive {:child_got, :ping}

      Process.exit(child, :kill)
    end

    test "broadcast to a different topic does not reach subscriber" do
      Local.subscribe("test:topic-a")
      Local.broadcast("test:topic-b", :wrong_topic)
      refute_receive :wrong_topic, 50
    end
  end

  describe "unsubscribe/1" do
    test "unsubscribed process no longer receives messages" do
      Local.subscribe("test:unsub")
      Local.unsubscribe("test:unsub")
      Local.broadcast("test:unsub", :should_not_arrive)
      refute_receive :should_not_arrive, 50
    end
  end

  describe "broadcast_batch/2" do
    test "delivers an EventBatch struct to the subscribed process" do
      batch = %EventBatch{
        batch_id: "b-1",
        command: :move_entity,
        correlation_id: "corr-1",
        occurred_at: ~U[2026-06-10 10:00:00Z],
        events: []
      }

      Local.subscribe("test:batch")
      Local.broadcast_batch("test:batch", batch)
      assert_receive %EventBatch{batch_id: "b-1"}
    end
  end

  describe "automatic cleanup on subscriber exit" do
    test "dead process is removed from subscriptions" do
      parent = self()

      child =
        spawn(fn ->
          Local.subscribe("test:cleanup")
          send(parent, :subscribed)

          receive do
            :exit -> :ok
          end
        end)

      assert_receive :subscribed

      ref = Process.monitor(child)
      send(child, :exit)
      assert_receive {:DOWN, ^ref, :process, ^child, _}

      assert Local.broadcast("test:cleanup", :after_exit) == :ok
      refute_receive :after_exit, 50
    end
  end
end
