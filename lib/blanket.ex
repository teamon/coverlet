defmodule Blanket do
  defmodule Lcov do
    @moduledoc """

    ## References
    - http://ltp.sourceforge.net/coverage/lcov/geninfo.1.php
    """
    def call(coverage) do
      IO.puts("\n\n == LCOV ==\n\n")

      File.mkdir_p("cover")

      File.open("cover/lcov.info", [:write], fn io ->
        for {file, modules} <- coverage do
          IO.binwrite(io, "SF:#{file}\n")

          for %{module: module, lines: [{n, _} | _] = lines} <- modules do
            for {n, c} <- lines do
              IO.binwrite(io, "DA:#{n},#{c}\n")
            end

            # IO.binwrite(io, "FN:#{n},#{module}\n")
          end

          IO.binwrite(io, "end_of_record\n")
        end
      end)
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

        if n > 0 do
          m = Enum.count(lines, &match?({_, 0}, &1))
          c = n - m
          stat = :io_lib.format("~10.. B ~10.. B ~8.2. f", [c, n, c * 100 / n])
          IO.puts("#{stat} | #{module}  (#{file})")
        end
      end
    end
  end

  defmodule HTML do
    require EEx
    dir = Path.join(__DIR__, "blanket/templates")
    EEx.function_from_file :defp, :render_index, Path.join(dir, "index.html.eex"), [:coverage]

    def call(coverage) do
      File.mkdir_p("cover")

      File.open("cover/cover.html", [:write], fn io ->
        IO.binwrite(io, render_index(merge(coverage)))
      end)
    end

    defp merge(coverage) do
      for {file, modules} <- coverage do
        lines = Enum.reduce(modules, %{}, fn %{lines: lines}, acc ->
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
      IO.inspect coverage
      coverage
      |> Enum.map(fn {file, lines} -> {file, percentage(lines)} end)
      |> Enum.sort_by(fn {file, perc} -> perc end)
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

  @reporters [
    # Lcov,
    # Json,
    Console,
    HTML
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
end
