# Blanket

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `blanket` to your list of dependencies in `mix.exs`:

```elixir
defmodule MyApp.MixProject do
  use Mix.Project

  def project do
    [
      # ...
      test_coverage: [tool: Blanket]
    ]
  end

  def deps do
    [
      {:blanket, "~> 0.1.0", only: [:test]}
    ]
  end
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/blanket](https://hexdocs.pm/blanket).
