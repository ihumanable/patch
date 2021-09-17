defmodule Patch.Test.AssertAnyCallTest do
  use ExUnit.Case
  use Patch

  alias Patch.Test.Support.Example

  describe "assert_any_call/2" do
    test "does not raise if a patched function has a call of any arity (/1)" do
      patch(Example, :function_with_multiple_arities, :patched_result)

      assert :patched_result == Example.function_with_multiple_arities(1)

      assert_any_call Example, :function_with_multiple_arities
    end

    test "does not raise if a patched function has a call of any arity (/2)" do
      patch(Example, :function_with_multiple_arities, :patched_result)

      assert :patched_result == Example.function_with_multiple_arities(1, 2)

      assert_any_call Example, :function_with_multiple_arities
    end

    test "does not raise if a patched function has a call of any arity (/3)" do
      patch(Example, :function_with_multiple_arities, :patched_result)

      assert :patched_result == Example.function_with_multiple_arities(1, 2, 3)

      assert_any_call Example, :function_with_multiple_arities
    end

    test "does not raise if a spied module has a call of any arity (/1)" do
      spy(Example)

      assert {1, 1} == Example.function_with_multiple_arities(1)

      assert_any_call Example, :function_with_multiple_arities
    end

    test "does not raise if a spied module has a call of any arity (/2)" do
      spy(Example)

      assert {{1, 2}, 2} == Example.function_with_multiple_arities(1, 2)

      assert_any_call Example, :function_with_multiple_arities
    end

    test "does not raise if a spied module has a call of any arity (/3)" do
      spy(Example)

      assert {{1, 2, 3}, 3} == Example.function_with_multiple_arities(1, 2, 3)

      assert_any_call Example, :function_with_multiple_arities
    end

    test "raises if a patched function has no calls" do
      patch(Example, :function_with_multiple_arities, :patched_result)

      assert_raise Patch.MissingCall, fn ->
        assert_any_call Example, :function_with_multiple_arities
      end
    end

    test "raises if a spied module function has no calls" do
      spy(Example)

      assert_raise Patch.MissingCall, fn ->
        assert_any_call Example, :function_with_multiple_arities
      end
    end
  end
end
