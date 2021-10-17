defmodule Patch.Test.User.Patch.CycleTest do
  use ExUnit.Case
  use Patch

  alias Patch.Test.Support.User.Patch.Cycle

  describe "patch/3 with cycles" do
    test "cycles the values on each call" do
      assert Cycle.example() == :original

      patch(Cycle, :example, cycle([1, 2, 3]))

      assert Cycle.example() == 1
      assert Cycle.example() == 2
      assert Cycle.example() == 3
      assert Cycle.example() == 1
      assert Cycle.example() == 2
      assert Cycle.example() == 3
      assert Cycle.example() == 1
    end



    test "cycles can contain functions as scalars" do
      assert Cycle.example() == :original

      callable = fn -> 2 end
      scalar_callable = scalar(callable)

      patch(Cycle, :example, cycle([1, scalar_callable, 3]))

      assert Cycle.example() == 1
      assert Cycle.example() == callable
      assert Cycle.example() == 3
      assert Cycle.example() == 1
      assert Cycle.example() == callable
      assert Cycle.example() == 3
      assert Cycle.example() == 1
    end
  end
end
