defmodule Patch.Test.User.Patch.CallableTest do
  use ExUnit.Case
  use Patch

  alias Patch.Test.Support.User.Patch.Callable

  describe "patch/3 with callable" do
    test "callable is evaluated" do
      assert Callable.example(:a) == {:original, :a}

      patch(Callable, :example, fn _ -> :patched end)

      assert Callable.example(:a) == :patched
    end

    test "callable is dispatched with application by default" do
      assert Callable.example(:a, :b, :c) == {:original, :a, :b, :c}

      patch(Callable, :example, fn a, b, c -> {:patched, a, b, c} end)

      assert Callable.example(:a, :b, :c) == {:patched, :a, :b, :c}
    end

    test "in apply mode, calling the patched function with an existing but unpatched arity passes through to the original module" do
      assert Callable.example(:a) == {:original, :a}
      assert Callable.example(:a, :b, :c) == {:original, :a, :b, :c}

      patch(Callable, :example, fn a, b, c -> {:patched, a, b, c} end)

      assert Callable.example(:a) == {:original, :a}
    end

    test "in apply mode, calling the patched function with arguments that do not match calls the original function" do
      assert Callable.example(:a, :b, :c) == {:original, :a, :b, :c}

      patch(Callable, :example, fn 1, b, c -> {:patched, 1, b, c} end)

      assert Callable.example(:a, :b, :c) == {:original, :a, :b, :c}

      assert Callable.example(1, :b, :c) == {:patched, 1, :b, :c}
    end

    test "callable can optionally be dispatched with all arguments in a list" do
      assert Callable.example(:a, :b, :c) == {:original, :a, :b, :c}

      callable = callable(fn arguments -> {:patched, arguments} end, :list)

      patch(Callable, :example, callable)

      assert Callable.example(:a, :b, :c) == {:patched, [:a, :b, :c]}
    end

    test "callable can cover multiple arities using list dispatch" do
      assert Callable.example(:a) == {:original, :a}

      callable = callable(fn
        [a] ->
          {:arity_1, a}

        [a, b, c] ->
          {:arity_3, a, b, c}
      end, :list)

      patch(Callable, :example, callable)

      assert Callable.example(:a) == {:arity_1, :a}
      assert Callable.example(:a, :b, :c) == {:arity_3, :a, :b, :c}
    end

    test "can be embedded in a cycle" do
      assert Callable.example(:a) == {:original, :a}

      patch(Callable, :example, cycle([1, fn arg -> {2, arg} end, 3]))

      assert Callable.example(:a) == 1
      assert Callable.example(:a) == {2, :a}
      assert Callable.example(:a) == 3
      assert Callable.example(:b) == 1
      assert Callable.example(:b) == {2, :b}
      assert Callable.example(:b) == 3
    end

    test "can be embedded in a sequence" do
      assert Callable.example(:a) == {:original, :a}

      patch(Callable, :example, sequence([1, fn arg -> {2, arg} end, fn arg -> {3, arg} end]))

      assert Callable.example(:a) == 1
      assert Callable.example(:a) == {2, :a}
      assert Callable.example(:a) == {3, :a}
      assert Callable.example(:b) == {3, :b}

    end
  end
end
