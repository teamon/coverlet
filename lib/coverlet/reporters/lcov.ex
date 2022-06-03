defmodule Coverlet.Reporters.LCOV do
  @moduledoc """

  ## References
  - http://ltp.sourceforge.net/coverage/lcov/geninfo.1.php
  """
  def call(coverage) do
    File.mkdir_p("cover")

    File.open("cover/lcov.info", [:write], fn io ->
      for %{path: path, lines: lines} <- coverage do
        IO.binwrite(io, "TN:\n")
        IO.binwrite(io, "SF:#{path}\n")

        for {n, c} <- lines do
          IO.binwrite(io, ["DA:#{n},#{c}\n"])
        end

        lf = Enum.count(lines)
        lh = Enum.count(lines, fn {_, c} -> c > 0 end)

        IO.binwrite(io, "LF:#{lf}\n")
        IO.binwrite(io, "LH:#{lh}\n")

        IO.binwrite(io, "end_of_record\n")
      end
    end)
  end
end
