defmodule Patch.Test.User.Patch.UnknownModuleTest do
  use ExUnit.Case
  use Patch

  describe "patching unknown module" do
    test "results in an exception" do
      assert_raise UndefinedFunctionError, fn ->
        patch(NoSuchModule, :function_that_does_not_exist, :patched)
      end

      assert_raise UndefinedFunctionError, fn ->
        patch(NoSuchModule, :function_that_does_not_exist, fn _x -> 42 end)
      end
    end
  end
end
