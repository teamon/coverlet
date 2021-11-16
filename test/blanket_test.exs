defmodule CoverletTest do
  use ExUnit.Case

  @appdir "test/example"

  @opts [
    cd: @appdir
  ]

  setup do
    File.rm_rf("#{@appdir}/cover")

    :ok
  end

  describe "mix test --cover" do
    test "generate HTML" do
      assert {_out, 0} = System.cmd("mix", ["test", "--cover"], @opts)
      assert File.exists?("#{@appdir}/cover/cover.html")
    end
  end
end
