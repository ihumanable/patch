defmodule Patch.Test.Support.User.RefuteAnyCall do
  def function_with_multiple_arities(a) do
    {:original, a}
  end

  def function_with_multiple_arities(a, b) do
    {:original, {a, b}}
  end

  def function_with_multiple_arities(a, b, c) do
    {:original, {a, b, c}}
  end

  def other_function(a) do
    {:other, a}
  end
end
