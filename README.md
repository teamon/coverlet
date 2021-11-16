# Coverlet

Code coverage raport generator.

## Installation

Add `coverlet` to your list of dependencies and set it as `test_coverage` tool in `mix.exs`:

```elixir
defmodule MyApp.MixProject do
  use Mix.Project

  def project do
    [
      # ...
      test_coverage: [tool: Coverlet]
    ]
  end

  def deps do
    [
      {:coverlet, "~> 0.1.0", only: [:test]}
    ]
  end
end
```

## Developing this library itself

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/coverlet](https://hexdocs.pm/coverlet).
