defmodule Patch.Test.Support.Unit.Annotated do
  def public_function(list) do
    Enum.map(list, &private_function/1) ++ [private_function(1), helper_capture()]
  end

  def helper_capture do
    &private_function/1
  end

  defp private_function(a) do
    {:private, a}
  end
end
