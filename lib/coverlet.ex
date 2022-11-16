defmodule Coverlet do
  @version Mix.Project.get().project[:version]

  def version, do: @version

  def start(compile_path, opts) do
    _ = :cover.start()

    case :cover.compile_beam_directory(compile_path |> to_charlist) do
      results when is_list(results) -> :ok
      {:error, _} -> Mix.raise("Failed to cover compile directory: " <> compile_path)
    end

    fn ->
      Mix.shell().info("\nGenerating cover results ...\n")
      coverage = generate_coverage()
      report(coverage, opts)
    end
  end

  defp generate_coverage do
    Enum.reduce(:cover.modules(), %{}, fn module, files ->
      source = to_string(module.module_info(:compile)[:source])
      path = Path.relative_to_cwd(source)

      if path != source do
        {:ok, analysis} = :cover.analyse(module, :calls, :line)
        lines = lines(analysis)

        case files[path] do
          nil -> Map.put(files, path, lines)
          list -> Map.put(files, path, list ++ lines)
        end
      else
        files
      end
    end)
    |> Enum.map(fn {path, lines} -> %{path: path, lines: lines} end)
  end

  defp lines(analysis) do
    analysis
    |> Enum.reduce([], fn
      {{_, n}, _}, xs when n <= 0 -> xs
      {{_, n}, c}, [{n, p} | xs] when c > p -> [{n, c} | xs]
      {{_, n}, _}, [{n, p} | xs] -> [{n, p} | xs]
      {{_, n}, c}, xs -> [{n, c} | xs]
    end)
    |> Enum.reverse()
  end

  @reporters [
    html: Coverlet.Reporters.HTML,
    lcov: Coverlet.Reporters.LCOV,
    console: Coverlet.Reporters.Console
  ]

  defp report(coverage, opts) do
    reporters = opts[:reporters] || [:html, :lcov, :console]

    for reporter <- reporters do
      mod = Keyword.fetch!(@reporters, reporter)
      mod.call(coverage)
    end
  end
end
