defmodule Patch.Test.Support.User.AssertAnyCall do
  def function_with_multiple_arities(a) do
    {:original, a}
  end

  def function_with_multiple_arities(a, b) do
    {:original, {a, b}}
  end

  def function_with_multiple_arities(a, b, c) do
    {:original, {a, b, c}}
  end
end
