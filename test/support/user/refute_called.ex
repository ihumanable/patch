defmodule Patch.Test.Support.User.RefuteCalled do
  def example(a, b) do
    {:original, a, b}
  end
end
