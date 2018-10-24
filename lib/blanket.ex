defmodule Blanket do
  @app :blanket
  @version Mix.Project.get().project[:version]
  @default_endpoint "https://todo-example.com"

  ## CONFIG

  def version, do: @version
  def token, do: get_config(:token, "BLANKET_TOKEN") || :unset
  def endpoint, do: get_config(:endpoint, "BLANKET_ENDPOINT") || @default_endpoint
  defp get_config(key, env), do: Application.get_env(@app, key) || System.get_env(env)

  ## COVERAGE TOOL IMPLEMENTATION

  def start(compile_path, opts) do
    Mix.shell().info("BLANKET compile_path: #{inspect(compile_path)}")
    Mix.shell().info("BLANKET opts:: #{inspect(opts)}")

    _ = :cover.start()

    case :cover.compile_beam_directory(compile_path |> to_charlist) do
      results when is_list(results) -> :ok
      {:error, _} -> Mix.raise("Failed to cover compile directory: " <> compile_path)
    end

    fn ->
      Mix.shell().info("\nBLANKET Generating cover results ...\n")
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

      coverage = %{
        module: module,
        lines: lines(analysis)
      }

      case files[path] do
        nil -> Map.put(files, path, [coverage])
        list -> Map.put(files, path, [coverage | list])
      end
    end)
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
      Blanket.Reporters.HTML,
      Blanket.Reporters.Remote
    ]

    for reporter <- reporters do
      reporter.call(coverage)
    end
  end
end
