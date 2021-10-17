defmodule Patch.Test.User.Patch.SequenceTest do
  use ExUnit.Case
  use Patch

  alias Patch.Test.Support.User.Patch.Sequence

  describe "patch/3 with sequence" do
    test "empty sequence always returns nil" do
      assert Sequence.example() == :original

      patch(Sequence, :example, sequence([]))

      assert is_nil(Sequence.example())
      assert is_nil(Sequence.example())
    end

    test "sequence of 1 always returns the only element" do
      assert Sequence.example() == :original

      patch(Sequence, :example, sequence([1]))

      assert Sequence.example() == 1
      assert Sequence.example() == 1
    end

    test "sequence of N returns the values in order" do
      assert Sequence.example() == :original

      patch(Sequence, :example, sequence([1, 2, 3]))

      assert Sequence.example() == 1
      assert Sequence.example() == 2
      assert Sequence.example() == 3
    end

    test "exhausted sequences continue to return the last element repeatedly" do
      assert Sequence.example() == :original

      patch(Sequence, :example, sequence([1, 2, 3]))

      assert Sequence.example() == 1
      assert Sequence.example() == 2
      assert Sequence.example() == 3
      assert Sequence.example() == 3
      assert Sequence.example() == 3
    end

    test "sequence can contain functions as scalars" do
      assert Sequence.example() == :original

      callable = fn -> 2 end
      scalar_callable = scalar(callable)

      patch(Sequence, :example, sequence([1, scalar_callable, 3]))

      assert Sequence.example() == 1
      assert Sequence.example() == callable
      assert Sequence.example() == 3
      assert Sequence.example() == 3
      assert Sequence.example() == 3
    end
  end
end
