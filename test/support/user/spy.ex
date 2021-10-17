defmodule Patch.Test.Support.User.Spy do
  def example(argument) do
    {:original, argument}
  end
end
