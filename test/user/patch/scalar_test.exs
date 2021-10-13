defmodule Patch.Test.User.Patch.ScalarTest do
  use ExUnit.Case
  use Patch

  alias Patch.Test.Support.User.Patch.Scalar

  describe "patch/3 with scalars" do
    test "returns the implicit scalar" do
      assert Scalar.example() == :original

      patch(Scalar, :example, :test_implicit_scalar)

      assert Scalar.example() == :test_implicit_scalar
    end

    test "returns the explicit scalar" do
      assert Scalar.example() == :original

      patch(Scalar, :example, scalar(:test_explicit_scalar))

      assert Scalar.example() == :test_explicit_scalar
    end

    test "functions can be wrapped with scalar/1" do
      assert Scalar.example() == :original

      function = fn ->
        :ok
      end

      patch(Scalar, :example, scalar(function))

      assert Scalar.example() == function
    end
  end
end
