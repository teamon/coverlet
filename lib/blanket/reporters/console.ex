defmodule Blanket.Reporters.Console do
  def call(coverage) do
    IO.puts "Percentage | File"
    IO.puts "-----------|--------------------------"

    for {path, percentage} <- summary(coverage) do
      IO.puts :io_lib.format("~10.2. f | ~s", [percentage, path])
    end
  end

  defp summary(coverage) do
    coverage
    |> Enum.map(fn %{path: path, lines: lines} -> {path, percentage(lines)} end)
    |> Enum.filter(fn {_, perc} -> perc end)
    |> Enum.sort_by(fn {_, perc} -> -perc end)
  end

  defp percentage(lines) do
    r = length(lines)

    if r > 0 do
      m = Enum.count(lines, &match?({_, 0}, &1))
      (r - m) * 100 / r
    else
      nil
    end
  end
end
