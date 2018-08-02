defmodule Example.Ninety do
  def one do
    1 + 1
  end

  def two do
    2 + 2
  end

  def three do
    3 + 3
  end

  def ninety do
    one() + two()
  end
end

defmodule Example.Sad do
  def very do
    x = 1 + 1
    2 + 2 + x
  end
end
