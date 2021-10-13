defmodule Patch.Test.User.ReflectionTest do
  use ExUnit.Case

  alias Patch.Reflection
  alias Patch.Test.Support.User.Reflection.ElixirTarget

  describe "find_functions/1" do
    test "returns the public functions of an Elixir Module" do
      functions = Reflection.find_functions(ElixirTarget)

      assert {:public_function, 1} in functions
      assert {:public_function, 2} in functions
      assert {:other_public_function, 0} in functions
    end

    test "does not return the private functions of an Elixir Module" do
      functions = Reflection.find_functions(ElixirTarget)

      refute {:private_function, 1} in functions
    end

    test "returns the public functions of an Erlang Module" do
      functions = Reflection.find_functions(:erlang_target)

      assert {:public_function, 1} in functions
      assert {:public_function, 2} in functions
      assert {:other_public_function, 0} in functions
    end

    test "does not return the private functions of an Erlang Module" do
      functions = Reflection.find_functions(:erlang_target)

      refute {:private_function, 1} in functions
    end

    test "empty list for unknown modules" do
      assert [] == Reflection.find_functions(UnknownModule)
    end
  end

  describe "find_arities/2" do
    test "returns the arities of the public function of an Elixir Module" do
      arities = Reflection.find_arities(ElixirTarget, :public_function)

      assert Enum.sort(arities) == [1, 2]
    end

    test "empty list for private functions of an Elixir Module" do
      assert [] == Reflection.find_arities(ElixirTarget, :private_function)
    end

    test "empty list for unknown functions of an Elixir Module" do
      assert [] == Reflection.find_arities(ElixirTarget, :unkonwn_function)
    end

    test "returns the arities of the public function of an Erlang Module" do
      arities = Reflection.find_arities(:erlang_target, :public_function)

      assert Enum.sort(arities) == [1, 2]
    end

    test "empty list for private functions of an Erlang Module" do
      assert [] == Reflection.find_arities(:erlang_target, :private_function)
    end

    test "empty list for unknown functions of an Erlang Module" do
      assert [] == Reflection.find_arities(:erlang_target, :unkonwn_function)
    end
  end
end
