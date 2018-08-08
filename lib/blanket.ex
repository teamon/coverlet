defmodule Blanket do
  defmodule Lcov do
    def call(coverage) do
      IO.puts("\n\n == LCOV ==\n\n")
      IO.puts("???")
    end
  end

  defmodule Json do
    def call(coverage) do
      IO.puts("\n\n == JSON ==\n\n")
      IO.puts(Jason.encode!(coverage))
    end
  end

  defmodule Console do
    def call(coverage) do
      IO.puts("   Covered   Relevant        % | Module  (File)")
      IO.puts("--------------------------------------------------------------")

      for {file, modules} <- coverage,
          %{module: module, lines: lines} <- modules do
        n = length(lines)
        m = Enum.count(lines, &match?([_, 0], &1))
        c = n - m

        stat = :io_lib.format("~10.. B ~10.. B ~8.2. f", [c, n, c * 100 / n])
        IO.puts("#{stat} | #{module}  (#{file})")
      end
    end
  end

  @reporters [
    Lcov,
    Json,
    Console
  ]

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

      for reporter <- @reporters do
        reporter.call(coverage)
      end
    end
  end

  defp generate_coverage do
    {:ok, cwd} = :file.get_cwd()
    cwdlen = length(cwd) + 1

    Enum.reduce(:cover.modules(), %{}, fn module, files ->
      source = module.module_info(:compile)[:source]
      path = :lists.nthtail(cwdlen, source)
      {:ok, analysis} = :cover.analyse(module, :calls, :line)

      coverage = %{
        module: module,
        lines: for({{_, n}, c} when n > 0 <- analysis, do: [n, c])
      }

      case files[path] do
        nil -> Map.put(files, path, [coverage])
        list -> Map.put(files, path, [coverage | list])
      end
    end)
  end
end
