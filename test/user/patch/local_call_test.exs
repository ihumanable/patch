defmodule Patch.Test.User.Patch.LocalCallTest do
  use ExUnit.Case
  use Patch

  alias Patch.Test.Support.User.Patch.LocalCall

  describe "local calls to public functions" do
    test "can be patched" do
      assert LocalCall.public_caller(:test_argument) == {:original, {:public, :test_argument}}

      patch(LocalCall, :public_function, :patched)

      assert LocalCall.public_caller(:test_argument) == {:original, :patched}
    end

    test "can be assert_called" do
      assert LocalCall.public_caller(:test_argument) == {:original, {:public, :test_argument}}

      patch(LocalCall, :public_function, :patched)

      assert LocalCall.public_caller(:test_argument) == {:original, :patched}

      assert_called LocalCall.public_function(:test_argument)
    end

    test "can be refute_called" do
      assert LocalCall.public_caller(:test_argument) == {:original, {:public, :test_argument}}

      patch(LocalCall, :public_function, :patched)

      refute_called LocalCall.public_function(:_)
    end
  end

  describe "local calls to private functions" do
    test "can be patched" do
      assert LocalCall.private_caller(:test_argument) == {:original, {:private, :test_argument}}

      patch(LocalCall, :private_function, :patched)

      assert LocalCall.private_caller(:test_argument) == {:original, :patched}
    end

    test "can be assert_called" do
      assert LocalCall.private_caller(:test_argument) == {:original, {:private, :test_argument}}

      patch(LocalCall, :private_function, :patched)

      assert LocalCall.private_caller(:test_argument) == {:original, :patched}

      assert_called LocalCall.private_function(:test_argument)
    end

    test "can be refute_called" do
      assert LocalCall.private_caller(:test_argument) == {:original, {:private, :test_argument}}

      patch(LocalCall, :private_function, :patched)

      refute_called LocalCall.private_function(:_)
    end
  end
end
