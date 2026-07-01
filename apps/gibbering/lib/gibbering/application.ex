defmodule Gibbering.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      GibberingWeb.Telemetry,
      Gibbering.Repo,
      GibberingTales.Catalogue.Cache,
      {DNSCluster, query: Application.get_env(:gibbering, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Gibbering.PubSub},
      {Registry, keys: :unique, name: Gibbering.GameRegistry},
      {DynamicSupervisor, name: Gibbering.SceneSupervisor, strategy: :one_for_one},
      metrics_store_child(),
      GibberingWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Gibbering.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  defp metrics_store_child do
    adapter =
      Application.get_env(:gibbering_engine, GibberingEngine.Monitoring.MetricsStore, [])
      |> Keyword.get(:adapter, Gibbering.Monitoring.Stores.Local)

    if adapter == Gibbering.Monitoring.Stores.Local do
      Gibbering.Monitoring.Stores.Local
    else
      # NoOp or other adapters don't need a supervised process
      {Task, fn -> :ok end}
    end
  end

  @impl true
  def config_change(changed, _new, removed) do
    GibberingWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
