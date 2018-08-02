defmodule BlanketTest do
  use ExUnit.Case
  doctest Blanket

  test "greets the world" do
    assert Blanket.hello() == :world
  end
end
