defmodule Patch.Test.Support.User.AssertCalled do
  def example(a, b) do
    {:original, a, b}
  end
end
