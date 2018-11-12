defmodule Blanket.Reporters.HTML do
  require EEx
  dir = Path.join(__DIR__, "html")
  EEx.function_from_file(:defp, :render_index, Path.join(dir, "index.html.eex"), [:coverage])

  def call(coverage) do
    dir = "cover"
    File.mkdir_p(dir)

    File.open("cover/cover.html", [:write], fn io ->
      IO.binwrite(io, render_index(coverage))
    end)

    IO.puts "Coverage reporte generated into #{dir} directory"
  end

  defp lines_with_hits(path, lines) do
    path
    |> File.stream!()
    |> Enum.with_index(1)
    |> Enum.map(fn {content, n} ->
      case List.keyfind(lines, n, 0) do
        {_, hits} -> {content, hits}
        nil -> {content, nil}
      end
    end)
  end

  defp line_class(nil), do: "ignore"
  defp line_class(0), do: "miss"
  defp line_class(_), do: "hit"

  defp summary(coverage) do
    coverage
    |> Enum.map(fn %{path: path, lines: lines} -> {path, percentage(lines)} end)
    |> Enum.sort_by(fn {_, perc} -> perc end)
  end

  defp percentage(lines) do
    r = length(lines)

    if r > 0 do
      m = Enum.count(lines, &match?({_, 0}, &1))
      (r - m) * 100 / r
    else
      0.0
    end
  end

  defp format_percentage(perc), do: :io_lib.format("~8.2. f", [perc])
end
