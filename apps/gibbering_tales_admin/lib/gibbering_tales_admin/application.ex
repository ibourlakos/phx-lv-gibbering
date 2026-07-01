defmodule GibberingTalesAdmin.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      GibberingTalesAdmin.Repo,
      {Phoenix.PubSub, name: GibberingTalesAdmin.PubSub},
      GibberingTalesAdmin.Endpoint
    ]

    opts = [strategy: :one_for_one, name: GibberingTalesAdmin.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    GibberingTalesAdmin.Endpoint.config_change(changed, removed)
    :ok
  end
end
