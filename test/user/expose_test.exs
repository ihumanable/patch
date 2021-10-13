defmodule Patch.Test.User.ExposeTest do
  use ExUnit.Case
  use Patch

  alias Patch.Test.Support.User.Expose

  describe "expose/2" do
    test "no change in visibility when :public" do
      assert Expose.public_function() == {:private_a, :private_b}

      assert_raise UndefinedFunctionError, fn ->
        apply(Expose, :private_function_a, [])
      end

      assert_raise UndefinedFunctionError, fn ->
        apply(Expose, :private_function_b, [])
      end

      expose(Expose, :public)

      assert Expose.public_function() == {:private_a, :private_b}

      assert_raise UndefinedFunctionError, fn ->
        apply(Expose, :private_function_a, [])
      end

      assert_raise UndefinedFunctionError, fn ->
        apply(Expose, :private_function_b, [])
      end
    end

    test "all private functions available when :all" do
      assert Expose.public_function() == {:private_a, :private_b}

      assert_raise UndefinedFunctionError, fn ->
        apply(Expose, :private_function_a, [])
      end

      assert_raise UndefinedFunctionError, fn ->
        apply(Expose, :private_function_b, [])
      end

      expose(Expose, :all)

      assert Expose.public_function() == {:private_a, :private_b}

      assert apply(Expose, :private_function_a, []) == :private_a

      assert apply(Expose, :private_function_b, []) == :private_b
    end

    test "a subset of functions can be exposed" do
      assert Expose.public_function() == {:private_a, :private_b}

      assert_raise UndefinedFunctionError, fn ->
        apply(Expose, :private_function_a, [])
      end

      assert_raise UndefinedFunctionError, fn ->
        apply(Expose, :private_function_b, [])
      end

      expose(Expose, private_function_a: 0)

      assert Expose.public_function() == {:private_a, :private_b}

      assert apply(Expose, :private_function_a, []) == :private_a

      assert_raise UndefinedFunctionError, fn ->
        apply(Expose, :private_function_b, [])
      end
    end
  end
end
