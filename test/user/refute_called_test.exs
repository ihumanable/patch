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

      refute_called RefuteCalled.example(3, :_)
      refute_called RefuteCalled.example(:_, 4)
    end

    test "partial calls that match raises UnexpectedCall" do
      patch(RefuteCalled, :example, :patched)

      assert RefuteCalled.example(1, 2) == :patched

      assert_raise Patch.UnexpectedCall, fn ->
        refute_called RefuteCalled.example(1, :_)
      end

      assert_raise Patch.UnexpectedCall, fn ->
        refute_called RefuteCalled.example(:_, 2)
      end
    end

    test "an uncalled function can be wildcard refuted" do
      patch(RefuteCalled, :example, :patched)

      refute_called RefuteCalled.example(:_, :_)
    end

    test "any call causes a wildcard refute to raise UnexpectedCall" do
      patch(RefuteCalled, :example, :patched)

      assert RefuteCalled.example(1, 2) == :patched

      assert_raise Patch.UnexpectedCall, fn ->
        refute_called RefuteCalled.example(:_, :_)
      end
    end
  end
end
