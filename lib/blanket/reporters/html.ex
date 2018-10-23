defmodule Blanket.Reporters.HTML do
  require EEx
  dir = Path.join(__DIR__, "html")
  EEx.function_from_file(:defp, :render_index, Path.join(dir, "index.html.eex"), [:coverage])

  def call(coverage) do
    File.mkdir_p("cover")

    File.open("cover/cover.html", [:write], fn io ->
      IO.binwrite(io, render_index(merge(coverage)))
    end)
  end

  defp merge(coverage) do
    for {file, modules} <- coverage do
      lines =
        Enum.reduce(modules, %{}, fn %{lines: lines}, acc ->
          Map.merge(acc, Enum.into(lines, %{}), fn _k, x, y -> x + y end)
        end)

      {file, lines}
    end
  end

  defp lines(file, lines) do
    file
    |> File.stream!()
    |> Enum.with_index(1)
    |> Enum.reduce([], fn {content, n}, acc -> [{lines[n], content} | acc] end)
    |> Enum.reverse()
  end

  defp line_class(nil), do: "ignore"
  defp line_class(0), do: "miss"
  defp line_class(_), do: "hit"

  defp summary(coverage) do
    IO.inspect(coverage)

    coverage
    |> Enum.map(fn {file, lines} -> {file, percentage(lines)} end)
    |> Enum.sort_by(fn {_, perc} -> perc end)
  end

  defp percentage(lines) do
    r = map_size(lines)

    if r > 0 do
      m = Enum.count(lines, &match?({_, 0}, &1))
      (r - m) * 100 / r
    else
      0.0
    end
  end

  defp format_percentage(perc), do: :io_lib.format("~8.2. f", [perc])
end
