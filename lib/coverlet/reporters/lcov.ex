defmodule Coverlet.Reporters.LCOV do
  @moduledoc """

  ## References
  - http://ltp.sourceforge.net/coverage/lcov/geninfo.1.php
  """
  def call(coverage) do
    File.mkdir_p("cover")

    File.open("cover/lcov.info", [:write], fn io ->
      for {file, modules} <- coverage do
        IO.binwrite(io, "SF:#{file}\n")

        for %{module: _module, lines: [{_, _} | _] = lines} <- modules do
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
