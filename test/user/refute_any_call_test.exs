defmodule Patch.Test.User.RefuteAnyCallTest do
  use ExUnit.Case
  use Patch

  alias Patch.Test.Support.User.RefuteAnyCall

  describe "refute_any_call/2" do
    test "raises if a patched function has a call of any arity (/1)" do
      patch(RefuteAnyCall, :function_with_multiple_arities, :patched_result)

      assert :patched_result == RefuteAnyCall.function_with_multiple_arities(1)

      assert_raise Patch.UnexpectedCall, fn ->
        refute_any_call RefuteAnyCall, :function_with_multiple_arities
      end
    end

    test "raises if a patched function has a call of any arity (/2)" do
      patch(RefuteAnyCall, :function_with_multiple_arities, :patched_result)

      assert :patched_result == RefuteAnyCall.function_with_multiple_arities(1, 2)

      assert_raise Patch.UnexpectedCall, fn ->
        refute_any_call RefuteAnyCall, :function_with_multiple_arities
      end
    end

    test "raises if a patched function has a call of any arity (/3)" do
      patch(RefuteAnyCall, :function_with_multiple_arities, :patched_result)

      assert :patched_result == RefuteAnyCall.function_with_multiple_arities(1, 2, 3)

      assert_raise Patch.UnexpectedCall, fn ->
        refute_any_call RefuteAnyCall, :function_with_multiple_arities
      end
    end

    test "raises if a spied module has a call of any arity (/1)" do
      spy(RefuteAnyCall)

      assert {:original, 1} == RefuteAnyCall.function_with_multiple_arities(1)

      assert_raise Patch.UnexpectedCall, fn ->
        refute_any_call RefuteAnyCall, :function_with_multiple_arities
      end
    end

    test "raises if a spied module has a call of any arity (/2)" do
      spy(RefuteAnyCall)

      assert {:original, {1, 2}} == RefuteAnyCall.function_with_multiple_arities(1, 2)

      assert_raise Patch.UnexpectedCall, fn ->
        refute_any_call RefuteAnyCall, :function_with_multiple_arities
      end
    end

    test "raises if a spied module has a call of any arity (/3)" do
      spy(RefuteAnyCall)

      assert {:original, {1, 2, 3}} == RefuteAnyCall.function_with_multiple_arities(1, 2, 3)

      assert_raise Patch.UnexpectedCall, fn ->
        refute_any_call RefuteAnyCall, :function_with_multiple_arities
      end
    end

    test "does not raise if a patched function has no calls" do
      patch(RefuteAnyCall, :function_with_multiple_arities, :patched_result)
      refute_any_call RefuteAnyCall, :function_with_multiple_arities
    end

    test "does not raise if a spied module function has no calls" do
      spy(RefuteAnyCall)
      refute_any_call RefuteAnyCall, :function_with_multiple_arities
    end
  end
end
