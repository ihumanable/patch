defmodule Patch.Test.Support.User.History do
  def public_caller(a) do
    {:original, public_function(a)}
  end

  def public_function(a) do
    {:public, a}
  end

  def private_caller(a) do
    {:original, private_function(a)}
  end

  ## Private

  defp private_function(a) do
    {:private, a}
  end
end
