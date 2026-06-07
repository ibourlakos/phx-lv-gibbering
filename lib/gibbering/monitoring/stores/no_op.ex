defmodule Gibbering.Monitoring.Stores.NoOp do
  @moduledoc "MetricsStore adapter for test environments — drops all writes, returns empty history."

  @behaviour Gibbering.Monitoring.MetricsStore

  @impl true
  def record(_campaign_id, _metric, _value), do: :ok

  @impl true
  def history(_campaign_id, _metric), do: []
end
