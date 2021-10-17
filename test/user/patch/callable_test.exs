defmodule Patch.Test.User.Patch.CallableTest do
  use ExUnit.Case
  use Patch

  alias Patch.Test.Support.User.Patch.Callable

  describe "patch/3 with callable" do
    test "callable is evaluated" do
      assert Callable.example(:test_argument) == {:original, :test_argument}

      patch(Callable, :example, fn _ -> :patched end)

      assert Callable.example(:test_argument) == :patched
    end

    test "callable is dispatched with application by default" do
      assert Callable.example(:a, :b, :c) == {:original, :a, :b, :c}

      patch(Callable, :example, fn a, b, c -> {:patched, a, b, c} end)

      assert Callable.example(:a, :b, :c) == {:patched, :a, :b, :c}
    end

    test "in apply mode, calling the patched function with the wrong arity raises" do
      assert Callable.example(:a, :b, :c) == {:original, :a, :b, :c}

      patch(Callable, :example, fn a, b, c -> {:patched, a, b, c} end)

      assert_raise BadArityError, fn ->
        Callable.example(:test_argument)
      end
    end

    test "callable can optionally be dispatched with all arguments in a list" do
      assert Callable.example(:a, :b, :c) == {:original, :a, :b, :c}

      callable = callable(fn arguments -> {:patched, arguments} end, :list)

      patch(Callable, :example, callable)

      assert Callable.example(:a, :b, :c) == {:patched, [:a, :b, :c]}
    end

    test "callable can cover multiple arities using list dispatch" do
      assert Callable.example(:test_argument) == {:original, :test_argument}

      callable = callable(fn
        [a] ->
          {:arity_1, a}

        [a, b, c] ->
          {:arity_3, a, b, c}
      end, :list)

      patch(Callable, :example, callable)

      assert Callable.example(:test_argument) == {:arity_1, :test_argument}
      assert Callable.example(:a, :b, :c) == {:arity_3, :a, :b, :c}
    end

    test "can be embedded in a cycle" do
      assert Callable.example(:test_argument) == {:original, :test_argument}

      patch(Callable, :example, cycle([1, fn arg -> {2, arg} end, 3]))

      assert Callable.example(:test_argument_1) == 1
      assert Callable.example(:test_argument_1) == {2, :test_argument_1}
      assert Callable.example(:test_argument_1) == 3
      assert Callable.example(:test_argument_2) == 1
      assert Callable.example(:test_argument_2) == {2, :test_argument_2}
      assert Callable.example(:test_argument_2) == 3
    end

    test "can be embedded in a sequence" do
      assert Callable.example(:test_argument) == {:original, :test_argument}

      patch(Callable, :example, sequence([1, fn arg -> {2, arg} end, fn arg -> {3, arg} end]))

      assert Callable.example(:test_argument_1) == 1
      assert Callable.example(:test_argument_1) == {2, :test_argument_1}
      assert Callable.example(:test_argument_1) == {3, :test_argument_1}
      assert Callable.example(:test_argument_2) == {3, :test_argument_2}

    end
  end
end
