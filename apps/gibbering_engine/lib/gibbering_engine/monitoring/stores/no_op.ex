defmodule GibberingEngine.Monitoring.Stores.NoOp do
  @moduledoc "MetricsStore adapter for test environments — drops all writes, returns empty history."

  @behaviour GibberingEngine.Monitoring.MetricsStore

  @impl true
  def record(_campaign_id, _metric, _value), do: :ok

  @impl true
  def history(_campaign_id, _metric), do: []

  @impl true
  def scene_snapshot(_campaign_id), do: {"?", "?"}
end
