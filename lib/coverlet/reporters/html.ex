defmodule Coverlet.Reporters.HTML do
  require EEx
  dir = Path.join(__DIR__, "html")
  EEx.function_from_file(:defp, :render_index, Path.join(dir, "index.html.eex"), [:coverage])

  def call(coverage) do
    dir = "cover"
    File.mkdir_p(dir)

    File.open("cover/cover.html", [:write], fn io ->
      coverage = Enum.sort_by(coverage, fn %{path: path} -> path end)
      IO.binwrite(io, render_index(coverage))
    end)

    IO.puts("Coverage reporte generated into #{dir} directory")
  end

  defp lines_with_hits(path, lines) do
    path
    |> File.stream!()
    |> Enum.with_index(1)
    |> Enum.map(fn {content, n} ->
      case List.keyfind(lines, n, 0) do
        {_, hits} -> {n, content, hits}
        nil -> {n, content, nil}
      end
    end)
  end

  defp line_class(nil), do: "ignore"
  defp line_class(0), do: "miss"
  defp line_class(_), do: "hit"

  defp summary_file_list(coverage) do
    coverage
    |> Enum.map(fn %{path: path, lines: lines} -> {path, perc(total(lines))} end)
    |> Enum.sort_by(fn {_, perc} -> perc end)
  end

  defp perc({_, 0}), do: 0.0
  defp perc({n, r}), do: n * 100 / r

  defp total(lines) do
    r = length(lines)

    if r > 0 do
      m = Enum.count(lines, &match?({_, 0}, &1))
      {r - m, r}
    else
      {0, 0}
    end
  end

  defp format_percentage(perc), do: :io_lib.format("~8.1. f%", [perc])

  defp p(perc), do: div(floor(perc), 10)

  defp summary_file_tree(coverage) do
    coverage
    |> Enum.reduce(%{}, fn %{path: path, lines: lines}, tree ->
      chunks = Path.split(path)
      tree_in(tree, chunks, {path, total(lines)})
    end)
    |> tree_map_depth_first(fn
      {dir, files} when is_list(files) ->
        {n, r} = Enum.reduce(files, {0, 0}, fn {_, {n, r}}, {sn, sr} -> {n + sn, r + sr} end)
        files = Enum.sort_by(files, fn {{_, file, _}, _} -> file end)
        {{:dir, dir, files}, {n, r}}

      {file, {path, {n, r}}} ->
        {{:file, file, path}, {n, r}}
    end)
  end

  defp render_tree(tree) do
    [
      ~s'<ul class="closed">',
      Enum.map(tree, fn
        {{:dir, dir, files}, {n, r}} ->
          [
            ~s'<li>',
            [
              [~s'<div  onclick="toggle(this)" class="f p', to_string(p(perc({n, r}))), ~s'">'],
              [
                [~s'<div class="gutter">', format_percentage(perc({n, r})), ~s'</div>'],
                [~s'<div class="caret">', dir, ~s'</div>']
              ],
              ~s'</div>',
              render_tree(files)
            ],
            ~s'</li>'
          ]

        {{:file, file, path}, {n, r}} ->
          [
            ~s'<li>',
            [
              [~s'<div class="f p', to_string(p(perc({n, r}))), ~s'">'],
              [
                [~s'<div class="gutter">', format_percentage(perc({n, r})), ~s'</div>'],
                [~s'<a href="#file-', path, ~s'">', file, ~s'</a>']
              ],
              ~s'</div>'
            ],
            ~s'</li>'
          ]
      end),
      ~s'</ul>'
    ]
  end

  defp tree_in(map, [key], val), do: Map.put(map, key, val)
  defp tree_in(map, [key | rest], val), do: Map.put(map, key, tree_in(map[key] || %{}, rest, val))

  defp tree_map_depth_first(map, fun) do
    Enum.map(map, fn
      {key, val} when is_map(val) ->
        fun.({key, tree_map_depth_first(val, fun)})

      {key, val} ->
        fun.({key, val})
    end)
  end
end
