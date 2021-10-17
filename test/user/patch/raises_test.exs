defmodule Patch.Test.User.Patch.RaisesTest do
  use ExUnit.Case
  use Patch

  alias Patch.Test.Support.User.Patch.Raises

  describe "patch/3 with raises" do
    test "can be used to raise a runtime exception" do
      assert Raises.example() == :original

      patch(Raises, :example, raises("patched"))

      assert_raise RuntimeError, "patched", fn ->
        Raises.example()
      end
    end

    test "can be used to raise a specific exception" do
      assert Raises.example() == :original

      patch(Raises, :example, raises(ArgumentError, message: "patched"))

      assert_raise ArgumentError, "patched", fn ->
        Raises.example()
      end
    end

    test "can be embedded in a cycle" do
      assert Raises.example() == :original

      patch(Raises, :example, cycle([1, raises("patched"), 2]))

      assert Raises.example() == 1
      assert_raise RuntimeError, "patched", fn ->
        Raises.example()
      end
      assert Raises.example() == 2

      assert Raises.example() == 1
      assert_raise RuntimeError, "patched", fn ->
        Raises.example()
      end
      assert Raises.example() == 2
    end

    test "can be embedded in a sequence" do
      assert Raises.example() == :original

      patch(Raises, :example, sequence([1, raises("patched"), 2]))

      assert Raises.example() == 1
      assert_raise RuntimeError, "patched", fn ->
        Raises.example()
      end
      assert Raises.example() == 2
      assert Raises.example() == 2
      assert Raises.example() == 2
    end
  end
end
