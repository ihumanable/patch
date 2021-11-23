defmodule Patch.Test.User.AssertCallTest do
  use ExUnit.Case
  use Patch

  alias Patch.Test.Support.User.AssertCall

  describe "assert_call/2" do
    test "passes if the call has already been made" do
      patch(AssertCall, :example, :patched)

      assert AssertCall.example(1, 2) == :patched

      assert_call AssertCall.example(1, 2)
    end

    test "passes if the call happens within the deadline" do
      patch(AssertCall, :example, :patched)

      spawn(fn ->
        Process.sleep(50)
        assert AssertCall.example(1, 2) == :patched
      end)

      refute_called AssertCall.example(1, 2)
      assert_call AssertCall.example(1, 2)
    end

    test "fails if the call never happens" do
      patch(AssertCall, :example, :patched)

      assert_raise Patch.DeadlineException, fn ->
        assert_call AssertCall.example(1, 2), 50
      end
    end

    test "fails if the call happens too late" do
      patch(AssertCall, :example, :patched)

      spawn(fn ->
        Process.sleep(100)
        assert AssertCall.example(1, 2) == :patched
      end)

      refute_called AssertCall.example(1, 2)
      assert_raise Patch.DeadlineException, fn ->
        assert_call AssertCall.example(1, 2), 50
      end
    end
  end
end
