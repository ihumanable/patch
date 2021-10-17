defmodule Patch.Test.User.AssertCalledTest do
  use ExUnit.Case
  use Patch

  alias Patch.Test.Support.User.AssertCalled

  describe "assert_called/1" do
    test "exact call can be asserted" do
      patch(AssertCalled, :example, :patched)

      assert AssertCalled.example(1, 2) == :patched

      assert_called AssertCalled.example(1, 2)
    end

    test "exact call mismatch raises MissingCall" do
      patch(AssertCalled, :example, :patched)

      assert AssertCalled.example(1, 2) == :patched

      assert_raise Patch.MissingCall, fn ->
        assert_called AssertCalled.example(3, 4)
      end
    end

    test "partial call can be asserted" do
      patch(AssertCalled, :example, :patched)

      assert AssertCalled.example(1, 2) == :patched

      assert_called AssertCalled.example(1, :_)
      assert_called AssertCalled.example(:_, 2)
    end

    test "partial call mismatch raises MissingCall" do
      patch(AssertCalled, :example, :patched)

      assert AssertCalled.example(1, 2) == :patched

      assert_raise Patch.MissingCall, fn ->
        assert_called AssertCalled.example(3, :_)
      end

      assert_raise Patch.MissingCall, fn ->
        assert_called AssertCalled.example(:_, 4)
      end
    end

    test "wildcard call can be asserted" do
      patch(AssertCalled, :example, :patched)

      assert AssertCalled.example(1, 2) == :patched

      assert_called AssertCalled.example(:_, :_)
    end

    test "wildcard call raises MissingCall when no calls present" do
      patch(AssertCalled, :example, :patched)

      assert_raise Patch.MissingCall, fn ->
        assert_called AssertCalled.example(:_, :_)
      end
    end
  end
end
