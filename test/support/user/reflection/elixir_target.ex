defmodule Patch.Test.Support.User.Reflection.ElixirTarget do
  def public_function(a) do
    private_function(a)
  end

  def public_function(a, b) do
    {:ok, a, b}
  end

  def other_public_function do
    :ok
  end

  ## Private

  defp private_function(a) do
    {:ok, a}
  end
end
