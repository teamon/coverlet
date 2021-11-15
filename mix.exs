defmodule Blanket.MixProject do
  use Mix.Project

  def project do
    [
      app: :blanket,
      version: "0.1.0",
      elixir: "~> 1.4",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: Blanket]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/example"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [extra_applications: [:logger, :tools, :eex]]
  end

  defp deps do
    []
  end
end
