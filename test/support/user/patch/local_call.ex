defmodule Patch.Test.Support.User.Patch.LocalCall do
  def public_caller(a) do
    {:original, public_function(a)}
  end

  def public_caller_string_interpolation(a) do
    {:original, "#{inspect(public_function(a))}"}
  end

  def public_function(a) do
    {:public, a}
  end

  def public_argument_consumer do
    Enum.map(public_arguments(), &(&1 * 2))
  end

  def public_arguments do
    [1, 2, 3]
  end

  def private_caller(a) do
    {:original, private_function(a)}
  end

  def private_caller_string_interpolation(a) do
    {:original, "#{inspect(private_function(a))}"}
  end

  ## Private

  defp private_function(a) do
    {:private, a}
  end
end
