defmodule Patch.Test.Support.User.AssertCalledOnce do
  def example(a, b) do
    {:original, a, b}
  end
end
