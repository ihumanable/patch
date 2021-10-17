defmodule Patch.Test.Support.User.Private do
  def public_function(a) do
    # This function has to exist so the compiler won't optimize away private_function/1
    private_function(a)
  end

  defp private_function(a) do
    {:private, a}
  end
end
