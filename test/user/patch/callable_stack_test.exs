defmodule Patch.Test.User.Patch.CallableStackTest do
  use ExUnit.Case
  use Patch

  alias Patch.Test.Support.User.Patch.CallableStack

  describe "patch/3 with Stacked Callables" do
    test "callable can replace non-callable without stacking" do
      assert CallableStack.example(:a) == {:original, :a}

      patch(CallableStack, :example, :patched)
      assert CallableStack.example(:a) == :patched

      patch(CallableStack, :example, fn a -> {:patched, a} end)
      assert CallableStack.example(:a) == {:patched, :a}
    end

    test "without matching, last assignment wins" do
      assert CallableStack.example(:a) == {:original, :a}

      patch(CallableStack, :example, fn a -> {:first_patch, a} end)
      assert CallableStack.example(:a) == {:first_patch, :a}

      patch(CallableStack, :example, fn a -> {:second_patch, a} end)
      assert CallableStack.example(:a) == {:second_patch, :a}
    end

    test "with matching and passthrough evaluation, latest matching wins with original called for no match" do
      assert CallableStack.example(:a) == {:original, :a}

      patch(CallableStack, :example, fn :a -> :first_patch end)
      patch(CallableStack, :example, fn :b -> :second_patch end)

      assert CallableStack.example(:a) == :first_patch
      assert CallableStack.example(:b) == :second_patch
      assert CallableStack.example(:c) == {:original, :c}
    end

    test "with matching and strict evaluation, latest matching wins with FunctionClauseError for no match" do
      assert CallableStack.example(:a) == {:original, :a}

      patch(CallableStack, :example, callable(fn :a -> :first_patch end, evaluate: :strict))
      patch(CallableStack, :example, fn :b -> :second_patch end)

      assert CallableStack.example(:a) == :first_patch
      assert CallableStack.example(:b) == :second_patch

      assert_raise FunctionClauseError, fn ->
        CallableStack.example(:c)
      end
    end

    test "stacking can be used on multiple arities" do
      assert CallableStack.example(:a) == {:original, :a}
      assert CallableStack.example(:a, :b, :c) == {:original, :a, :b, :c}

      patch(CallableStack, :example, fn a -> {:patched, a} end)
      patch(CallableStack, :example, fn a, b, c -> {:patched, a, b, c} end)

      assert CallableStack.example(:a) == {:patched, :a}
      assert CallableStack.example(:a, :b, :c) == {:patched, :a, :b, :c}
    end

    test "stacking can be used with multiple arities and pattern matching" do
      assert CallableStack.example(:a) == {:original, :a}
      assert CallableStack.example(:a, :b, :c) == {:original, :a, :b, :c}

      patch(CallableStack, :example, fn 1 -> :first_patch end)
      patch(CallableStack, :example, fn 1, b, c -> {:second_patch, 1, b, c} end)

      patch(CallableStack, :example, fn 2 -> :third_patch end)
      patch(CallableStack, :example, fn 2, b, c -> {:fourth_patch, 2, b, c} end)

      assert CallableStack.example(1) == :first_patch
      assert CallableStack.example(1, 2, 3) == {:second_patch, 1, 2, 3}

      assert CallableStack.example(2) == :third_patch
      assert CallableStack.example(2, 3, 4) == {:fourth_patch, 2, 3, 4}

      assert CallableStack.example(:a) == {:original, :a}
      assert CallableStack.example(:a, :b, :c) == {:original, :a, :b, :c}
    end
  end
end
