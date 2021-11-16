defmodule Coverlet do
  @version Mix.Project.get().project[:version]

  def version, do: @version

  def start(compile_path, _opts) do
    _ = :cover.start()

    case :cover.compile_beam_directory(compile_path |> to_charlist) do
      results when is_list(results) -> :ok
      {:error, _} -> Mix.raise("Failed to cover compile directory: " <> compile_path)
    end

    fn ->
      Mix.shell().info("\nGenerating cover results ...\n")
      coverage = generate_coverage()
      report(coverage)
    end
  end

  defp generate_coverage do
    {:ok, cwd} = :file.get_cwd()
    cwdlen = length(cwd) + 1

    Enum.reduce(:cover.modules(), %{}, fn module, files ->
      source = module.module_info(:compile)[:source]
      path = to_string(:lists.nthtail(cwdlen, source))
      {:ok, analysis} = :cover.analyse(module, :calls, :line)
      lines = lines(analysis)

      case files[path] do
        nil -> Map.put(files, path, lines)
        list -> Map.put(files, path, list ++ lines)
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

  defp report(coverage) do
    reporters = [
      Coverlet.Reporters.HTML,
      Coverlet.Reporters.LCOV,
      Coverlet.Reporters.Console
    ]

    for reporter <- reporters do
      reporter.call(coverage)
    end
  end
end
