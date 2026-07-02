defmodule Gibbering.MixProject do
  use Mix.Project

  def project do
    [
      app: :gibbering,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      in_umbrella: true
    ]
  end

  def application do
    [
      mod: {Gibbering.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    []
  end
end
