defmodule GibberingEngine.EventBus.Local do
  @moduledoc """
  `GibberingEngine.EventBus` adapter for unit tests. No `Phoenix.PubSub` process required.

  Maintains a subscription table in ETS. Broadcast delivers messages to all
  subscribed PIDs via `send/2` — callers can still use `assert_receive` in tests.
  Subscriptions are monitored: a subscriber's entries are removed automatically
  when the process exits.

  Start it under a test supervisor:

      start_supervised!(GibberingEngine.EventBus.Local)

  Then point the adapter at it for the duration of the test:

      Application.put_env(:gibbering_engine, GibberingEngine.EventBus, adapter: GibberingEngine.EventBus.Local)

  """

  use GenServer

  @behaviour GibberingEngine.EventBus

  @table __MODULE__

  # --- GenServer lifecycle ---

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl GenServer
  def init(_) do
    :ets.new(@table, [:named_table, :public, :bag])
    {:ok, %{monitors: %{}}}
  end

  @impl GenServer
  def handle_call({:subscribe, topic, pid}, _from, state) do
    :ets.insert(@table, {topic, pid})
    ref = Process.monitor(pid)
    monitors = Map.put(state.monitors, ref, pid)
    {:reply, :ok, %{state | monitors: monitors}}
  end

  @impl GenServer
  def handle_call({:unsubscribe, topic, pid}, _from, state) do
    :ets.delete_object(@table, {topic, pid})
    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_info({:DOWN, ref, :process, pid, _reason}, state) do
    :ets.match_delete(@table, {:_, pid})
    monitors = Map.delete(state.monitors, ref)
    {:noreply, %{state | monitors: monitors}}
  end

  # --- EventBus callbacks ---

  @impl GibberingEngine.EventBus
  def subscribe(topic) do
    GenServer.call(__MODULE__, {:subscribe, topic, self()})
  end

  @impl GibberingEngine.EventBus
  def unsubscribe(topic) do
    GenServer.call(__MODULE__, {:unsubscribe, topic, self()})
  end

  @impl GibberingEngine.EventBus
  def broadcast(topic, message) do
    @table
    |> :ets.lookup(topic)
    |> Enum.each(fn {_topic, pid} -> send(pid, message) end)

    :ok
  end

  @impl GibberingEngine.EventBus
  def broadcast_batch(topic, batch) do
    broadcast(topic, batch)
  end
end
