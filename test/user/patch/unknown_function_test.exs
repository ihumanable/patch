defmodule Patch.Test.User.Patch.UnknownFunctionTest do
  use ExUnit.Case
  use Patch

  alias Patch.Test.Support.User.Patch.UnknownFunction

  describe "patching unknown functions" do
    test "is a no-op" do
      patch(UnknownFunction, :function_that_does_not_exist, :patched)

      assert_raise UndefinedFunctionError, fn ->
        apply(UnknownFunction, :function_that_does_not_exist, [])
      end
    end
  end
end
