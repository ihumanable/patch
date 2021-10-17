defmodule Patch.Test.User.PrivateTest do
  use ExUnit.Case
  use Patch

  alias Patch.Test.Support.User.Private

  describe "private/1" do
    test "can call a private function without raising a compiler warning" do
      assert_raise UndefinedFunctionError, fn ->
        private(Private.private_function(:test_argument))
      end
    end

    test "can call an exposed private function without raising a compiler warning" do
      expose(Private, :all)

      patch(Private, :private_function, :patched)

      assert private(Private.private_function(:test_argument)) == :patched
    end
  end
end
