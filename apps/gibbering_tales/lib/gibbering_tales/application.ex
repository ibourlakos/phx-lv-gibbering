defmodule GibberingTales.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      GibberingTales.Repo
    ]

    opts = [strategy: :one_for_one, name: GibberingTales.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
