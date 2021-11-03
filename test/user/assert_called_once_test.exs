defmodule Patch.Test.User.AssertCalledOnecTest do
  use ExUnit.Case
  use Patch

  alias Patch.Test.Support.User.AssertCalledOnce

  describe "assert_called_once/1" do
    test "exact call can be asserted" do
      patch(AssertCalledOnce, :example, :patched)

      assert AssertCalledOnce.example(1, 2) == :patched

      assert_called_once AssertCalledOnce.example(1, 2)
    end

    test "exact call mismatch raises MissingCall" do
      patch(AssertCalledOnce, :example, :patched)

      assert AssertCalledOnce.example(1, 2) == :patched

      assert_raise Patch.MissingCall, fn ->
        assert_called_once AssertCalledOnce.example(3, 4)
      end
    end

    test "exact call after multiple calls raises UnexpectedCall" do
      patch(AssertCalledOnce, :example, :patched)

      assert AssertCalledOnce.example(1, 2) == :patched
      assert AssertCalledOnce.example(1, 2) == :patched

      assert_raise Patch.UnexpectedCall, fn ->
        assert_called_once AssertCalledOnce.example(1, 2)
      end
    end

    test "partial call can be asserted" do
      patch(AssertCalledOnce, :example, :patched)

      assert AssertCalledOnce.example(1, 2) == :patched

      assert_called_once AssertCalledOnce.example(1, _)
      assert_called_once AssertCalledOnce.example(_, 2)
    end

    test "partial call mismatch raises MissingCall" do
      patch(AssertCalledOnce, :example, :patched)

      assert AssertCalledOnce.example(1, 2) == :patched

      assert_raise Patch.MissingCall, fn ->
        assert_called_once AssertCalledOnce.example(3, _)
      end

      assert_raise Patch.MissingCall, fn ->
        assert_called_once AssertCalledOnce.example(_, 4)
      end
    end

    test "partial call after multiple calls raises UnexpectedCall" do
      patch(AssertCalledOnce, :example, :patched)

      assert AssertCalledOnce.example(1, 2) == :patched
      assert AssertCalledOnce.example(1, 3) == :patched
      assert AssertCalledOnce.example(3, 2) == :patched


      assert_raise Patch.UnexpectedCall, fn ->
        assert_called_once AssertCalledOnce.example(1, _)
      end

      assert_raise Patch.UnexpectedCall, fn ->
        assert_called_once AssertCalledOnce.example(_, 2)
      end
    end

    test "wildcard call can be asserted" do
      patch(AssertCalledOnce, :example, :patched)

      assert AssertCalledOnce.example(1, 2) == :patched

      assert_called_once AssertCalledOnce.example(_, _)
    end

    test "wildcard call raises MissingCall when no calls present" do
      patch(AssertCalledOnce, :example, :patched)

      assert_raise Patch.MissingCall, fn ->
        assert_called_once AssertCalledOnce.example(_, _)
      end
    end

    test "wildcard call raises UnexpectedCall when multiple calls present" do
      patch(AssertCalledOnce, :example, :patched)

      assert AssertCalledOnce.example(1, 2) == :patched
      assert AssertCalledOnce.example(3, 4) == :patched

      assert_raise Patch.UnexpectedCall, fn ->
        assert_called_once AssertCalledOnce.example(_, _)
      end
    end

    test "exception formatting with no calls" do
      patch(AssertCalledOnce, :example, :patched)

      expected_message = """
      \n
      Expected the following call to occur exactly once, but call occurred 0 times:

        Patch.Test.Support.User.AssertCalledOnce.example(1, 2)

      Calls which were received (matching calls are marked with *):

        [No Calls Received]
      """

      assert_raise Patch.MissingCall, expected_message, fn ->
        assert_called_once AssertCalledOnce.example(1, 2)
      end
    end

    test "exception formatting with non-matching calls" do
      patch(AssertCalledOnce, :example, :patched)

      assert AssertCalledOnce.example(1, 2) == :patched

      expected_message = """
      \n
      Expected the following call to occur exactly once, but call occurred 0 times:

        Patch.Test.Support.User.AssertCalledOnce.example(3, 4)

      Calls which were received (matching calls are marked with *):

        1. Patch.Test.Support.User.AssertCalledOnce.example(1, 2)
      """

      assert_raise Patch.MissingCall, expected_message, fn ->
        assert_called_once AssertCalledOnce.example(3, 4)
      end
    end

    test "exception formatting with wrong number of matched calls" do
      patch(AssertCalledOnce, :example, :patched)

      assert AssertCalledOnce.example(1, 2) == :patched
      assert AssertCalledOnce.example(3, 4) == :patched
      assert AssertCalledOnce.example(1, 2) == :patched

      expected_message = """
      \n
      Expected the following call to occur exactly once, but call occurred 2 times:

        Patch.Test.Support.User.AssertCalledOnce.example(1, 2)

      Calls which were received (matching calls are marked with *):

      * 1. Patch.Test.Support.User.AssertCalledOnce.example(1, 2)
        2. Patch.Test.Support.User.AssertCalledOnce.example(3, 4)
      * 3. Patch.Test.Support.User.AssertCalledOnce.example(1, 2)
      """

      assert_raise Patch.UnexpectedCall, expected_message, fn ->
        assert_called_once AssertCalledOnce.example(1, 2)
      end
    end
  end
end
