defmodule GibberingEngine.Monitoring.MetricsStore do
  @moduledoc """
  Behaviour for campaign metric storage. Adapters: `Stores.Local` (in gibbering app, default in prod), `Stores.NoOp` (default in engine).
  Active adapter is read from application config at call time.
  """

  @callback record(campaign_id :: integer, metric :: String.t(), value :: number()) :: :ok
  @callback history(campaign_id :: integer, metric :: String.t()) ::
              [{DateTime.t(), number()}]
  @callback scene_snapshot(campaign_id :: integer) ::
              {entity_count :: non_neg_integer() | String.t(), phase :: atom() | String.t()}

  defp adapter do
    Application.get_env(:gibbering_engine, __MODULE__, [])
    |> Keyword.get(:adapter, GibberingEngine.Monitoring.Stores.NoOp)
  end

  @doc "Record a metric sample for a campaign."
  def record(campaign_id, metric, value), do: adapter().record(campaign_id, metric, value)

  @doc "Return recent samples as `[{datetime, value}]`, oldest first."
  def history(campaign_id, metric), do: adapter().history(campaign_id, metric)

  @doc "Return the latest observed entity count and phase for a campaign."
  def scene_snapshot(campaign_id), do: adapter().scene_snapshot(campaign_id)
end
