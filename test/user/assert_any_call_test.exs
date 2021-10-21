defmodule Patch.Test.User.AssertAnyCallTest do
  use ExUnit.Case
  use Patch

  alias Patch.Test.Support.User.AssertAnyCall

  describe "assert_any_call/1" do
    test "does not raise if a patched function has a call of any arity (/1)" do
      patch(AssertAnyCall, :function_with_multiple_arities, :patched_result)

      assert :patched_result == AssertAnyCall.function_with_multiple_arities(1)

      assert_any_call AssertAnyCall.function_with_multiple_arities
    end

    test "does not raise if a patched function has a call of any arity (/2)" do
      patch(AssertAnyCall, :function_with_multiple_arities, :patched_result)

      assert :patched_result == AssertAnyCall.function_with_multiple_arities(1, 2)

      assert_any_call AssertAnyCall.function_with_multiple_arities
    end

    test "does not raise if a patched function has a call of any arity (/3)" do
      patch(AssertAnyCall, :function_with_multiple_arities, :patched_result)

      assert :patched_result == AssertAnyCall.function_with_multiple_arities(1, 2, 3)

      assert_any_call AssertAnyCall.function_with_multiple_arities
    end

    test "does not raise if a spied module has a call of any arity (/1)" do
      spy(AssertAnyCall)

      assert {:original, 1} == AssertAnyCall.function_with_multiple_arities(1)

      assert_any_call AssertAnyCall.function_with_multiple_arities
    end

    test "does not raise if a spied module has a call of any arity (/2)" do
      spy(AssertAnyCall)

      assert {:original, {1, 2}} == AssertAnyCall.function_with_multiple_arities(1, 2)

      assert_any_call AssertAnyCall.function_with_multiple_arities
    end

    test "does not raise if a spied module has a call of any arity (/3)" do
      spy(AssertAnyCall)

      assert {:original, {1, 2, 3}} == AssertAnyCall.function_with_multiple_arities(1, 2, 3)

      assert_any_call AssertAnyCall.function_with_multiple_arities
    end

    test "raises if a patched function has no calls" do
      patch(AssertAnyCall, :function_with_multiple_arities, :patched_result)

      assert_raise Patch.MissingCall, fn ->
        assert_any_call AssertAnyCall.function_with_multiple_arities
      end
    end

    test "raises if a spied module function has no calls" do
      spy(AssertAnyCall)

      assert_raise Patch.MissingCall, fn ->
        assert_any_call AssertAnyCall.function_with_multiple_arities
      end
    end

    test "raises in the presence of calls to other functions" do
      patch(AssertAnyCall, :other_function, :patched)

      assert AssertAnyCall.other_function(1) == :patched

      assert_raise Patch.MissingCall, fn ->
        assert_any_call AssertAnyCall.function_with_multiple_arities
      end
    end

    test "exception formatting" do
      patch(AssertAnyCall, :other_function, :patched_result)
      patch(AssertAnyCall, :function_with_multiple_arities, :patched_result)

      assert AssertAnyCall.other_function(1) == :patched_result

      expected_message = """
      \n
      Expected any call to the following function:

        Patch.Test.Support.User.AssertAnyCall.function_with_multiple_arities

      Calls which were received (matching calls are marked with *):

        1. Patch.Test.Support.User.AssertAnyCall.other_function(1)
      """

      assert_raise Patch.MissingCall, expected_message, fn ->
        assert_any_call AssertAnyCall.function_with_multiple_arities
      end
    end

  end

  describe "assert_any_call/2" do
    test "does not raise if a patched function has a call of any arity (/1)" do
      patch(AssertAnyCall, :function_with_multiple_arities, :patched_result)

      assert :patched_result == AssertAnyCall.function_with_multiple_arities(1)

      assert_any_call AssertAnyCall, :function_with_multiple_arities
    end

    test "does not raise if a patched function has a call of any arity (/2)" do
      patch(AssertAnyCall, :function_with_multiple_arities, :patched_result)

      assert :patched_result == AssertAnyCall.function_with_multiple_arities(1, 2)

      assert_any_call AssertAnyCall, :function_with_multiple_arities
    end

    test "does not raise if a patched function has a call of any arity (/3)" do
      patch(AssertAnyCall, :function_with_multiple_arities, :patched_result)

      assert :patched_result == AssertAnyCall.function_with_multiple_arities(1, 2, 3)

      assert_any_call AssertAnyCall, :function_with_multiple_arities
    end

    test "does not raise if a spied module has a call of any arity (/1)" do
      spy(AssertAnyCall)

      assert {:original, 1} == AssertAnyCall.function_with_multiple_arities(1)

      assert_any_call AssertAnyCall, :function_with_multiple_arities
    end

    test "does not raise if a spied module has a call of any arity (/2)" do
      spy(AssertAnyCall)

      assert {:original, {1, 2}} == AssertAnyCall.function_with_multiple_arities(1, 2)

      assert_any_call AssertAnyCall, :function_with_multiple_arities
    end

    test "does not raise if a spied module has a call of any arity (/3)" do
      spy(AssertAnyCall)

      assert {:original, {1, 2, 3}} == AssertAnyCall.function_with_multiple_arities(1, 2, 3)

      assert_any_call AssertAnyCall, :function_with_multiple_arities
    end

    test "raises if a patched function has no calls" do
      patch(AssertAnyCall, :function_with_multiple_arities, :patched_result)

      assert_raise Patch.MissingCall, fn ->
        assert_any_call AssertAnyCall, :function_with_multiple_arities
      end
    end

    test "raises if a spied module function has no calls" do
      spy(AssertAnyCall)

      assert_raise Patch.MissingCall, fn ->
        assert_any_call AssertAnyCall, :function_with_multiple_arities
      end
    end

    test "raises in the presence of calls to other functions" do
      patch(AssertAnyCall, :other_function, :patched)

      assert AssertAnyCall.other_function(1) == :patched

      assert_raise Patch.MissingCall, fn ->
        assert_any_call AssertAnyCall, :function_with_multiple_arities
      end
    end

    test "exception formatting" do
      patch(AssertAnyCall, :other_function, :patched_result)
      patch(AssertAnyCall, :function_with_multiple_arities, :patched_result)

      assert AssertAnyCall.other_function(1) == :patched_result

      expected_message = """
      \n
      Expected any call to the following function:

        Patch.Test.Support.User.AssertAnyCall.function_with_multiple_arities

      Calls which were received (matching calls are marked with *):

        1. Patch.Test.Support.User.AssertAnyCall.other_function(1)
      """

      assert_raise Patch.MissingCall, expected_message, fn ->
        assert_any_call AssertAnyCall, :function_with_multiple_arities
      end
    end
  end
end
