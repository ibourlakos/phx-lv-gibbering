defmodule GibberingTales.MixProject do
  use Mix.Project

  def project do
    [
      app: :gibbering_tales,
      version: "0.1.0",
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      in_umbrella: true
    ]
  end

  def application do
    [
      mod: {GibberingTales.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:gibbering_engine, in_umbrella: true},
      {:ecto_sql, "~> 3.13"},
      {:postgrex, ">= 0.0.0"},
      {:pbkdf2_elixir, "~> 2.0"},
      {:jason, "~> 1.2"},
      {:req, "~> 0.5"}
    ]
  end

  defp aliases do
    [
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
