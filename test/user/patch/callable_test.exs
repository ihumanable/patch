defmodule Patch.Test.User.Patch.CallableTest do
  use ExUnit.Case
  use Patch

  alias Patch.Test.Support.User.Patch.Callable

  describe "patch/3 with callable using default configuration" do
    test "uses default values for dispatch and evaluation" do
      callable = patch(Callable, :example, callable(fn _ -> :patched end))

      assert callable.dispatch == :apply
      assert callable.evaluate == :passthrough
    end
  end

  describe "patch/3 with callable using apply dispatch and passthrough evaluation" do
    test "calling the patched function with an existing but unpatched arity passes through to the original module" do
      assert Callable.example(:a) == {:original, :a}
      assert Callable.example(:a, :b, :c) == {:original, :a, :b, :c}

      patch(Callable, :example, fn a, b, c -> {:patched, a, b, c} end)

      assert Callable.example(:a) == {:original, :a}
      assert Callable.example(:a, :b, :c) == {:patched, :a, :b, :c}
    end

    test "calling the patched function with arguments that do not match calls the original function" do
      assert Callable.example(:a, :b, :c) == {:original, :a, :b, :c}

      patch(Callable, :example, fn 1, b, c -> {:patched, 1, b, c} end)

      assert Callable.example(:a, :b, :c) == {:original, :a, :b, :c}
      assert Callable.example(1, :b, :c) == {:patched, 1, :b, :c}
    end
  end

  describe "patch/3 with callable using apply dispatch and strict evaluation" do
    test "calling the patched function with an existing but unpatched arity raises BadArityError" do
      assert Callable.example(:a) == {:original, :a}
      assert Callable.example(:a, :b, :c) == {:original, :a, :b, :c}

      patch(Callable, :example, callable(fn a, b, c -> {:patched, a, b, c} end, evaluate: :strict))

      assert_raise BadArityError, fn ->
        Callable.example(:a)
      end

      assert Callable.example(:a, :b, :c) == {:patched, :a, :b, :c}
    end

    test "calling the patched function with arguments that do not match raises FunctionClauseError" do
      assert Callable.example(:a, :b, :c) == {:original, :a, :b, :c}

      patch(Callable, :example, callable(fn 1, b, c -> {:patched, 1, b, c} end, evaluate: :strict))

      assert_raise FunctionClauseError, fn ->
        Callable.example(:a, :b, :c)
      end

      assert Callable.example(1, :b, :c) == {:patched, 1, :b, :c}
    end
  end

  describe "patch/3 with callable using list dispatch and passthrough evaluation" do
    test "provides all arguments in a list using the legacy convention" do
      assert Callable.example(:a) == {:original, :a}
      assert Callable.example(:a, :b, :c) == {:original, :a, :b, :c}

      callable = callable(fn arguments -> {:patched, arguments} end, :list)

      patch(Callable, :example, callable)

      assert Callable.example(:a) == {:patched, [:a]}
      assert Callable.example(:a, :b, :c) == {:patched, [:a, :b, :c]}
    end

    test "provides all arguments in a list using the options convention" do
      assert Callable.example(:a) == {:original, :a}
      assert Callable.example(:a, :b, :c) == {:original, :a, :b, :c}

      callable = callable(fn arguments -> {:patched, arguments} end, dispatch: :list)

      patch(Callable, :example, callable)

      assert Callable.example(:a) == {:patched, [:a]}
      assert Callable.example(:a, :b, :c) == {:patched, [:a, :b, :c]}
    end

    test "callable can cover multiple arities using list dispatch" do
      assert Callable.example(:a) == {:original, :a}
      assert Callable.example(:a, :b, :c) == {:original, :a, :b, :c}

      callable = callable(fn
        [a] ->
          {:patched, a}

        [a, b, c] ->
          {:patched, a, b, c}
      end, dispatch: :list)

      patch(Callable, :example, callable)

      assert Callable.example(:a) == {:patched, :a}
      assert Callable.example(:a, :b, :c) == {:patched, :a, :b, :c}
    end

    test "calling the patched function with an existing but unpatched arity passes through to the original module" do
      assert Callable.example(:a) == {:original, :a}
      assert Callable.example(:a, :b, :c) == {:original, :a, :b, :c}

      callable = callable(fn
        [a] ->
          {:patched, a}
      end, dispatch: :list)

      patch(Callable, :example, callable)

      assert Callable.example(:a) == {:patched, :a}
      assert Callable.example(:a, :b, :c) == {:original, :a, :b, :c}
    end

    test "calling the patched function with arguments that do not match calls the original function" do
      assert Callable.example(:a) == {:original, :a}

      callable = callable(fn
        [1] ->
          {:patched, 1}
      end, dispatch: :list)

      patch(Callable, :example, callable)

      assert Callable.example(1) == {:patched, 1}
      assert Callable.example(:a) == {:original, :a}
    end
  end

  describe "patch/3 with callable using list dispach and strict evaluation" do
    test "provides all arguments in a list using the options convention" do
      assert Callable.example(:a) == {:original, :a}
      assert Callable.example(:a, :b, :c) == {:original, :a, :b, :c}

      callable = callable(fn arguments ->
        {:patched, arguments}
      end, dispatch: :list, evaluate: :strict)

      patch(Callable, :example, callable)

      assert Callable.example(:a) == {:patched, [:a]}
      assert Callable.example(:a, :b, :c) == {:patched, [:a, :b, :c]}
    end

    test "callable can cover multiple arities using list dispatch" do
      assert Callable.example(:a) == {:original, :a}
      assert Callable.example(:a, :b, :c) == {:original, :a, :b, :c}

      callable = callable(fn
        [a] ->
          {:patched, a}

        [a, b, c] ->
          {:patched, a, b, c}
      end, dispatch: :list, evaluate: :strict)

      patch(Callable, :example, callable)

      assert Callable.example(:a) == {:patched, :a}
      assert Callable.example(:a, :b, :c) == {:patched, :a, :b, :c}
    end

    test "calling the patched function with an existing but unpatched arity raises FunctionClauseError" do
      assert Callable.example(:a) == {:original, :a}
      assert Callable.example(:a, :b, :c) == {:original, :a, :b, :c}

      callable = callable(fn
        [a] ->
          {:patched, a}
      end, dispatch: :list, evaluate: :strict)

      patch(Callable, :example, callable)

      assert Callable.example(:a) == {:patched, :a}

      assert_raise FunctionClauseError, fn ->
        Callable.example(:a, :b, :c)
      end
    end

    test "calling the patched function with arguments that do not match raises FunctionClauseError" do
      assert Callable.example(:a) == {:original, :a}

      callable = callable(fn
        [1] ->
          {:patched, 1}
      end, dispatch: :list, evaluate: :strict)

      patch(Callable, :example, callable)

      assert Callable.example(1) == {:patched, 1}

      assert_raise FunctionClauseError, fn ->
        Callable.example(:a)
      end
    end
  end

  describe "callable configuration" do
    test "unknown keys in the configuration raises a ConfigurationError" do
      assert_raise Patch.ConfigurationError, fn ->
        callable(fn -> :ok end, unknown: :option)
      end
    end

    test "invalid dispatch modes raises a ConfigurationError" do
      assert_raise Patch.ConfigurationError, fn ->
        callable(fn -> :ok end, dispatch: :invalid)
      end
    end

    test "invalid evaluate modes raises a ConfigurationError" do
      assert_raise Patch.ConfigurationError, fn ->
        callable(fn -> :ok end, evaluate: :invalid)
      end
    end
  end

  describe "callable embedding" do
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
