defmodule Patch.Test.User.Patch.ThrowsTest do
  use ExUnit.Case
  use Patch

  alias Patch.Test.Support.User.Patch.Throws

  describe "patch/3 with throws" do
    test "can be used to throw a value" do
      assert Throws.example() == :original

      patch(Throws, :example, throws(:patched))

      assert catch_throw(Throws.example()) == :patched
    end

    test "can be embedded in a cycle" do
      assert Throws.example() == :original

      patch(Throws, :example, cycle([1, throws(:patched), 2]))

      assert Throws.example() == 1
      assert catch_throw(Throws.example()) == :patched
      assert Throws.example() == 2

      assert Throws.example() == 1
      assert catch_throw(Throws.example()) == :patched
      assert Throws.example() == 2
    end

    test "can be embedded in a sequence" do
      assert Throws.example() == :original

      patch(Throws, :example, sequence([1, throws(:patched), 2]))

      assert Throws.example() == 1
      assert catch_throw(Throws.example()) == :patched
      assert Throws.example() == 2
      assert Throws.example() == 2
      assert Throws.example() == 2
    end
  end
end
