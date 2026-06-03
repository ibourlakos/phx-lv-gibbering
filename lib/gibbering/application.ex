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
      {DNSCluster, query: Application.get_env(:gibbering, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Gibbering.PubSub},
      {Registry, keys: :unique, name: Gibbering.GameRegistry},
      GibberingWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Gibbering.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    GibberingWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
