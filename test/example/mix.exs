defmodule Example.MixProject do
  use Mix.Project

  def project do
    [
      app: :example,
      version: "0.1.0",
      elixir: "~> 1.4",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: Coverlet]
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [{:coverlet, path: "../..", only: [:dev, :test]}]
  end
end
