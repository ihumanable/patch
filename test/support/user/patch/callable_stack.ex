defmodule Patch.Test.Support.User.Patch.CallableStack do
  def example(argument) do
    {:original, argument}
  end

  def example(a, b, c) do
    {:original, a, b, c}
  end
end
