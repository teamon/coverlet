defmodule Blanket.Reporters.Console do
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
