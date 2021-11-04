defmodule Patch.Test.User.RefuteCalledTest do
  use ExUnit.Case
  use Patch

  alias Patch.Test.Support.User.RefuteCalled

  describe "refute_called/1" do
    test "exact call can be refuted" do
      patch(RefuteCalled, :example, :patched)

      assert RefuteCalled.example(1, 2) == :patched

      refute_called RefuteCalled.example(3, 4)
    end

    test "exact calls that have happened raise UnexpectedCall" do
      patch(RefuteCalled, :example, :patched)

      assert RefuteCalled.example(1, 2) == :patched

      assert_raise Patch.UnexpectedCall, fn ->
        refute_called RefuteCalled.example(1, 2)
      end
    end

    test "partial call can be refuted" do
      patch(RefuteCalled, :example, :patched)

      assert RefuteCalled.example(1, 2) == :patched

      refute_called RefuteCalled.example(3, _)
      refute_called RefuteCalled.example(_, 4)
    end

    test "partial calls that match raises UnexpectedCall" do
      patch(RefuteCalled, :example, :patched)

      assert RefuteCalled.example(1, 2) == :patched

      assert_raise Patch.UnexpectedCall, fn ->
        refute_called RefuteCalled.example(1, _)
      end

      assert_raise Patch.UnexpectedCall, fn ->
        refute_called RefuteCalled.example(_, 2)
      end
    end

    test "an uncalled function can be wildcard refuted" do
      patch(RefuteCalled, :example, :patched)

      refute_called RefuteCalled.example(_, _)
    end

    test "any call causes a wildcard refute to raise UnexpectedCall" do
      patch(RefuteCalled, :example, :patched)

      assert RefuteCalled.example(1, 2) == :patched

      assert_raise Patch.UnexpectedCall, fn ->
        refute_called RefuteCalled.example(_, _)
      end
    end

    test "exception formatting" do
      patch(RefuteCalled, :example, :patched)

      assert RefuteCalled.example(1, 2) == :patched
      assert RefuteCalled.example(3, 4) == :patched
      assert RefuteCalled.example(1, 2) == :patched

      expected_message = """
      \n
      Unexpected call received:

        Patch.Test.Support.User.RefuteCalled.example(1, 2)

      Calls which were received (matching calls are marked with *):

      * 1. Patch.Test.Support.User.RefuteCalled.example(1, 2)
        2. Patch.Test.Support.User.RefuteCalled.example(3, 4)
      * 3. Patch.Test.Support.User.RefuteCalled.example(1, 2)
      """

      assert_raise Patch.UnexpectedCall, expected_message, fn ->
        refute_called RefuteCalled.example(1, 2)
      end
    end
  end

  describe "refute_called/2" do
    test "exact call can be refuted with literal count" do
      patch(RefuteCalled, :example, :patched)

      assert RefuteCalled.example(1, 2) == :patched

      refute_called RefuteCalled.example(1, 2), 2

      assert RefuteCalled.example(1, 2) == :patched

      refute_called RefuteCalled.example(1, 2), 1
    end

    test "exact call can be refuted with expression count" do
      patch(RefuteCalled, :example, :patched)

      unexpected_count = 2

      assert RefuteCalled.example(1, 2) == :patched

      refute_called RefuteCalled.example(1, 2), unexpected_count

      assert RefuteCalled.example(1, 2) == :patched

      refute_called RefuteCalled.example(1, 2), unexpected_count - 1
    end

    test "exact calls that have happened count times raise UnexpectedCall" do
      patch(RefuteCalled, :example, :patched)

      assert RefuteCalled.example(1, 2) == :patched

      assert_raise Patch.UnexpectedCall, fn ->
        refute_called RefuteCalled.example(1, 2), 1
      end
    end

    test "partial call can be refuted with literal count" do
      patch(RefuteCalled, :example, :patched)

      assert RefuteCalled.example(1, 2) == :patched

      refute_called RefuteCalled.example(1, _), 2
      refute_called RefuteCalled.example(_, 2), 2
    end

    test "partial call can be refuted with expression count" do
      patch(RefuteCalled, :example, :patched)

      assert RefuteCalled.example(1, 2) == :patched

      unexpected_count = 2

      refute_called RefuteCalled.example(1, _), unexpected_count
      refute_called RefuteCalled.example(_, 2), unexpected_count + 1
    end

    test "partial calls that match raises UnexpectedCall" do
      patch(RefuteCalled, :example, :patched)

      assert RefuteCalled.example(1, 2) == :patched

      assert_raise Patch.UnexpectedCall, fn ->
        refute_called RefuteCalled.example(1, _), 1
      end

      assert_raise Patch.UnexpectedCall, fn ->
        refute_called RefuteCalled.example(_, 2), 1
      end
    end

    test "an uncalled function can be wildcard refuted" do
      patch(RefuteCalled, :example, :patched)

      refute_called RefuteCalled.example(_, _), 1
    end

    test "any call causes a wildcard refute to raise UnexpectedCall" do
      patch(RefuteCalled, :example, :patched)

      assert RefuteCalled.example(1, 2) == :patched

      assert_raise Patch.UnexpectedCall, fn ->
        refute_called RefuteCalled.example(_, _), 1
      end
    end

    test "exception formatting" do
      patch(RefuteCalled, :example, :patched)

      assert RefuteCalled.example(1, 2) == :patched
      assert RefuteCalled.example(3, 4) == :patched
      assert RefuteCalled.example(1, 2) == :patched

      expected_message = """
      \n
      Expected any count except 2 of the following calls, but found 2:

        Patch.Test.Support.User.RefuteCalled.example(1, 2)

      Calls which were received (matching calls are marked with *):

      * 1. Patch.Test.Support.User.RefuteCalled.example(1, 2)
        2. Patch.Test.Support.User.RefuteCalled.example(3, 4)
      * 3. Patch.Test.Support.User.RefuteCalled.example(1, 2)
      """

      assert_raise Patch.UnexpectedCall, expected_message, fn ->
        refute_called RefuteCalled.example(1, 2), 2
      end
    end
  end
end
