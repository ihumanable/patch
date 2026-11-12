defmodule Patch.Test.Support.User.Cover.Counted do
  def public_function(value) do
    doubled = private_function(value)

    if doubled > 10 do
      :large
    else
      :small
    end
  end

  def mocked_function(value) do
    tripled = value * 3
    tripled - 1
  end

  defp private_function(value) do
    squared = value * value
    squared * 2
  end
end
