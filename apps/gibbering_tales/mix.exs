defmodule GibberingTales.MixProject do
  use Mix.Project

  def project do
    [
      app: :gibbering_tales,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      in_umbrella: true
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:gibbering_engine, in_umbrella: true}
    ]
  end
end
