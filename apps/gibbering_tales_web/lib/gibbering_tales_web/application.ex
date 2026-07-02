defmodule GibberingTalesWeb.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      GibberingTalesWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:gibbering_tales_web, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: GibberingTales.PubSub},
      {Registry, keys: :unique, name: GibberingTalesWeb.GameRegistry},
      {DynamicSupervisor, name: GibberingTalesWeb.SceneSupervisor, strategy: :one_for_one},
      metrics_store_child(),
      GibberingTalesWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: GibberingTalesWeb.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    GibberingTalesWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp metrics_store_child do
    adapter =
      Application.get_env(:gibbering_engine, GibberingEngine.Monitoring.MetricsStore, [])
      |> Keyword.get(:adapter, GibberingTalesWeb.Monitoring.Stores.Local)

    if adapter == GibberingTalesWeb.Monitoring.Stores.Local do
      GibberingTalesWeb.Monitoring.Stores.Local
    else
      {Task, fn -> :ok end}
    end
  end
end
