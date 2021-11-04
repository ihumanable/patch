defmodule Patch.Test.User.RefuteCalledOnecTest do
  use ExUnit.Case
  use Patch

  alias Patch.Test.Support.User.RefuteCalledOnce

  describe "refute_called_once/1" do
    test "exact call can be refuted" do
      patch(RefuteCalledOnce, :example, :patched)

      assert RefuteCalledOnce.example(1, 2) == :patched

      refute_called_once RefuteCalledOnce.example(3, 4)
    end

    test "exact call that have happened raise UnexpectedCall" do
      patch(RefuteCalledOnce, :example, :patched)

      assert RefuteCalledOnce.example(1, 2) == :patched

      assert_raise Patch.UnexpectedCall, fn ->
        refute_called_once RefuteCalledOnce.example(1, 2)
      end
    end

    test "exact call after multiple calls can be refuted" do
      patch(RefuteCalledOnce, :example, :patched)

      assert RefuteCalledOnce.example(1, 2) == :patched
      assert RefuteCalledOnce.example(1, 2) == :patched

      refute_called_once RefuteCalledOnce.example(1, 2)
    end

    test "partial call can be refuted" do
      patch(RefuteCalledOnce, :example, :patched)

      assert RefuteCalledOnce.example(1, 2) == :patched

      refute_called_once RefuteCalledOnce.example(3, _)
      refute_called_once RefuteCalledOnce.example(_, 4)
    end

    test "partial call that match raises UnexpectedCall" do
      patch(RefuteCalledOnce, :example, :patched)

      assert RefuteCalledOnce.example(1, 2) == :patched

      assert_raise Patch.UnexpectedCall, fn ->
        refute_called_once RefuteCalledOnce.example(1, _)
      end

      assert_raise Patch.UnexpectedCall, fn ->
        refute_called_once RefuteCalledOnce.example(_, 2)
      end
    end

    test "partial call after multiple calls can be refuted" do
      patch(RefuteCalledOnce, :example, :patched)

      assert RefuteCalledOnce.example(1, 2) == :patched
      assert RefuteCalledOnce.example(1, 3) == :patched
      assert RefuteCalledOnce.example(3, 2) == :patched

      refute_called_once RefuteCalledOnce.example(1, _)
      refute_called_once RefuteCalledOnce.example(_, 2)
    end

    test "an uncalled function can be wildcard refuted" do
      patch(RefuteCalledOnce, :example, :patched)

      refute_called_once RefuteCalledOnce.example(_, _)
    end

    test "any call causes a wildcard to raise UnexpectedCall" do
      patch(RefuteCalledOnce, :example, :patched)

      assert RefuteCalledOnce.example(1, 2) == :patched

      assert_raise Patch.UnexpectedCall, fn ->
        refute_called_once RefuteCalledOnce.example(_, _)
      end
    end

    test "wildcard call with multiple calls can be refuted" do
      patch(RefuteCalledOnce, :example, :patched)

      assert RefuteCalledOnce.example(1, 2) == :patched
      assert RefuteCalledOnce.example(3, 4) == :patched

      refute_called_once RefuteCalledOnce.example(_, _)
    end

    test "exception formatting" do
      patch(RefuteCalledOnce, :example, :patched)

      assert RefuteCalledOnce.example(1, 2) == :patched
      assert RefuteCalledOnce.example(3, 4) == :patched

      expected_message = """
      \n
      Expected the following call to occur any number of times but once, but it occurred once:

        Patch.Test.Support.User.RefuteCalledOnce.example(1, 2)

      Calls which were received (matching calls are marked with *):

      * 1. Patch.Test.Support.User.RefuteCalledOnce.example(1, 2)
        2. Patch.Test.Support.User.RefuteCalledOnce.example(3, 4)
      """

      assert_raise Patch.UnexpectedCall, expected_message, fn ->
        refute_called_once RefuteCalledOnce.example(1, 2)
      end
    end
  end
end
