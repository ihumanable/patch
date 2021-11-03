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

      assert_called AssertCalled.example(1, _)
      assert_called AssertCalled.example(_, 2)
    end

    test "partial call mismatch raises MissingCall" do
      patch(AssertCalled, :example, :patched)

      assert AssertCalled.example(1, 2) == :patched

      assert_raise Patch.MissingCall, fn ->
        assert_called AssertCalled.example(3, _)
      end

      assert_raise Patch.MissingCall, fn ->
        assert_called AssertCalled.example(_, 4)
      end
    end

    test "wildcard call can be asserted" do
      patch(AssertCalled, :example, :patched)

      assert AssertCalled.example(1, 2) == :patched

      assert_called AssertCalled.example(_, _)
    end

    test "wildcard call raises MissingCall when no calls present" do
      patch(AssertCalled, :example, :patched)

      assert_raise Patch.MissingCall, fn ->
        assert_called AssertCalled.example(_, _)
      end
    end

    test "variable match" do
      patch(AssertCalled, :example, :patched)

      assert AssertCalled.example(1, 2) == :patched

      assert_called AssertCalled.example(a, b)

      assert a == 1
      assert b == 2
    end

    test "partial map match" do
      patch(AssertCalled, :example, :patched)

      assert AssertCalled.example(%{a: 1, b: 2}, :test) == :patched

      assert_called AssertCalled.example(%{a: 1}, _)
    end

    test "patterns can express arbitrary complexity" do
      patch(AssertCalled, :example, :patched)

      assert AssertCalled.example([1, 2, 3, %{a: 1, b: 2}], []) == :patched

      x = 1

      assert_called AssertCalled.example([^x, y, _z, %{b: 2}] = first, [])

      assert first == [1, 2, 3, %{a: 1, b: 2}]
      assert y == 2
    end

    test "exception formatting with no calls" do
      patch(AssertCalled, :example, :patched)

      expected_message = """
      \n
      Expected but did not receive the following call:

        Patch.Test.Support.User.AssertCalled.example(1, 2)

      Calls which were received (matching calls are marked with *):

        [No Calls Received]
      """

      assert_raise Patch.MissingCall, expected_message, fn ->
        assert_called AssertCalled.example(1, 2)
      end
    end

    test "exception formatting with non-matching calls" do
      patch(AssertCalled, :example, :patched)

      assert AssertCalled.example(1, 2) == :patched

      expected_message = """
      \n
      Expected but did not receive the following call:

        Patch.Test.Support.User.AssertCalled.example(3, 4)

      Calls which were received (matching calls are marked with *):

        1. Patch.Test.Support.User.AssertCalled.example(1, 2)
      """

      assert_raise Patch.MissingCall, expected_message, fn ->
        assert_called AssertCalled.example(3, 4)
      end
    end
  end

  describe "assert_called/2" do
    test "exact call can be asserted with literal count" do
      patch(AssertCalled, :example, :patched)

      assert AssertCalled.example(1, 2) == :patched

      assert_called AssertCalled.example(1, 2), 1

      assert AssertCalled.example(1, 2) == :patched

      assert_called AssertCalled.example(1, 2), 2
    end

    test "exact call can be asserted with expression count" do
      patch(AssertCalled, :example, :patched)

      expected_count = 1

      assert AssertCalled.example(1, 2) == :patched

      assert_called AssertCalled.example(1, 2), expected_count

      assert AssertCalled.example(1, 2) == :patched

      assert_called AssertCalled.example(1, 2), expected_count + 1
    end

    test "exact call mismatch raises MissingCall" do
      patch(AssertCalled, :example, :patched)

      assert AssertCalled.example(1, 2) == :patched

      assert_raise Patch.MissingCall, fn ->
        assert_called AssertCalled.example(3, 4), 1
      end
    end

    test "exact call with too high an expected count raises MissingCall" do
      patch(AssertCalled, :example, :patched)

      assert AssertCalled.example(1, 2) == :patched

      assert_raise Patch.MissingCall, fn ->
        assert_called AssertCalled.example(1, 2), 2
      end
    end

    test "exact call with too low an expected count raises UnexpectedCall" do
      patch(AssertCalled, :example, :patched)

      assert AssertCalled.example(1, 2) == :patched
      assert AssertCalled.example(1, 2) == :patched

      assert_raise Patch.UnexpectedCall, fn ->
        assert_called AssertCalled.example(1, 2), 1
      end
    end

    test "partial call can be asserted with literal count" do
      patch(AssertCalled, :example, :patched)

      assert AssertCalled.example(1, 2) == :patched

      assert_called AssertCalled.example(1, _), 1
      assert_called AssertCalled.example(_, 2), 1

      assert AssertCalled.example(1, 2) == :patched

      assert_called AssertCalled.example(1, _), 2
      assert_called AssertCalled.example(_, 2), 2
    end

    test "partial call mismatch raises MissingCall" do
      patch(AssertCalled, :example, :patched)

      assert AssertCalled.example(1, 2) == :patched

      assert_raise Patch.MissingCall, fn ->
        assert_called AssertCalled.example(3, _), 1
      end

      assert_raise Patch.MissingCall, fn ->
        assert_called AssertCalled.example(_, 4), 1
      end
    end

    test "partial call with too high an expected count raises MissingCall" do
      patch(AssertCalled, :example, :patched)

      assert AssertCalled.example(1, 2) == :patched

      assert_raise Patch.MissingCall, fn ->
        assert_called AssertCalled.example(1, _), 2
      end

      assert_raise Patch.MissingCall, fn ->
        assert_called AssertCalled.example(_, 2), 2
      end
    end

    test "partial call with too low an expected count raises UnexpectedCall" do
      patch(AssertCalled, :example, :patched)

      assert AssertCalled.example(1, 2) == :patched
      assert AssertCalled.example(1, 3) == :patched
      assert AssertCalled.example(3, 2) == :patched

      assert_raise Patch.UnexpectedCall, fn ->
        assert_called AssertCalled.example(1, _), 1
      end

      assert_raise Patch.UnexpectedCall, fn ->
        assert_called AssertCalled.example(_, 2), 1
      end
    end

    test "wildcard call can be asserted" do
      patch(AssertCalled, :example, :patched)

      assert AssertCalled.example(1, 2) == :patched

      assert_called AssertCalled.example(_, _), 1

      assert AssertCalled.example(3, 4) == :patched

      assert_called AssertCalled.example(_, _), 2
    end

    test "wildcard call with too high an expected count raises MissingCall" do
      patch(AssertCalled, :example, :patched)

      assert AssertCalled.example(1, 2) == :patched

      assert_raise Patch.MissingCall, fn ->
        assert_called AssertCalled.example(_, _), 2
      end
    end

    test "wildcard call with too low an expected count raises UnexpectedCall" do
      patch(AssertCalled, :example, :patched)

      assert AssertCalled.example(1, 2) == :patched
      assert AssertCalled.example(3, 4) == :patched

      assert_raise Patch.UnexpectedCall, fn ->
        assert_called AssertCalled.example(_, _), 1
      end
    end

    test "variable matches only call" do
      patch(AssertCalled, :example, :patched)

      assert AssertCalled.example(1, 2) == :patched

      assert_called AssertCalled.example(a, b), 1

      assert a == 1
      assert b == 2
    end

    test "variable matches latest call" do
      patch(AssertCalled, :example, :patched)

      assert AssertCalled.example(1, 2) == :patched
      assert AssertCalled.example(3, 4) == :patched

      assert_called AssertCalled.example(a, b), 2

      assert a == 3
      assert b == 4
    end

    test "pattern match matches latest call" do
      patch(AssertCalled, :example, :patched)

      assert AssertCalled.example(1, 2) == :patched
      assert AssertCalled.example(1, 3) == :patched

      assert_called AssertCalled.example(1, a), 2

      assert a == 3
    end

    test "exception formatting with no calls" do
      patch(AssertCalled, :example, :patched)

      expected_message = """
      \n
      Expected 1 of the following calls, but found 0:

        Patch.Test.Support.User.AssertCalled.example(1, 2)

      Calls which were received (matching calls are marked with *):

        [No Calls Received]
      """

      assert_raise Patch.MissingCall, expected_message, fn ->
        assert_called AssertCalled.example(1, 2), 1
      end
    end

    test "exception formatting with non-matching calls" do
      patch(AssertCalled, :example, :patched)

      assert AssertCalled.example(1, 2) == :patched

      expected_message = """
      \n
      Expected 1 of the following calls, but found 0:

        Patch.Test.Support.User.AssertCalled.example(3, 4)

      Calls which were received (matching calls are marked with *):

        1. Patch.Test.Support.User.AssertCalled.example(1, 2)
      """

      assert_raise Patch.MissingCall, expected_message, fn ->
        assert_called AssertCalled.example(3, 4), 1
      end
    end

    test "exception formatting with wrong number of matched calls" do
      patch(AssertCalled, :example, :patched)

      assert AssertCalled.example(1, 2) == :patched
      assert AssertCalled.example(3, 4) == :patched
      assert AssertCalled.example(1, 2) == :patched

      expected_message = """
      \n
      Expected 1 of the following calls, but found 2:

        Patch.Test.Support.User.AssertCalled.example(1, 2)

      Calls which were received (matching calls are marked with *):

      * 1. Patch.Test.Support.User.AssertCalled.example(1, 2)
        2. Patch.Test.Support.User.AssertCalled.example(3, 4)
      * 3. Patch.Test.Support.User.AssertCalled.example(1, 2)
      """

      assert_raise Patch.UnexpectedCall, expected_message, fn ->
        assert_called AssertCalled.example(1, 2), 1
      end
    end

    test "exception formatting with wrong pinned variables" do
      patch(AssertCalled, :example, :patched)

      assert AssertCalled.example(1, 2) == :patched
      assert AssertCalled.example(1, 3) == :patched
      assert AssertCalled.example(1, 4) == :patched

      x = 1

      expected_message = """
      \n
      Expected 1 of the following calls, but found 0:

        Patch.Test.Support.User.AssertCalled.example(1, ^x)

      Calls which were received (matching calls are marked with *):

        1. Patch.Test.Support.User.AssertCalled.example(1, 2)
        2. Patch.Test.Support.User.AssertCalled.example(1, 3)
        3. Patch.Test.Support.User.AssertCalled.example(1, 4)
      """

      assert_raise Patch.MissingCall, expected_message, fn ->
        assert_called AssertCalled.example(1, ^x), 1
      end
    end
  end
end
