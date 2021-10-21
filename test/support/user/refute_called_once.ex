defmodule Patch.Test.Support.User.RefuteCalledOnce do
  def example(a, b) do
    {:original, a, b}
  end
end
