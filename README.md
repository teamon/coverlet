# Blanket

**TODO: Add description**

## Installation

Add `blanket` to your list of dependencies and set it as `test_coverage` tool in `mix.exs`:

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

## Developing this library itself

Use `BLANKET_ENDPOINT` to point the reporter to localhost.

```
BLANKET_ENDPOINT=http://localhost:4000 BLANKET_TOKEN=xyz mix test --cover
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/blanket](https://hexdocs.pm/blanket).
