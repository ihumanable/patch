defmodule Patch.Test.Support.User.Expose do
  def public_function do
    {private_function_a(), private_function_b()}
  end

  defp private_function_a do
    :private_a
  end

  defp private_function_b do
    :private_b
  end
end
