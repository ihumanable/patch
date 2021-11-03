defmodule Patch.Test.Unit.Patch.MacroTest do
  use ExUnit.Case
  use Patch

  require Patch.Macro

  describe "match?/2" do
    test "can match literal expressions" do
      assert Patch.Macro.match?(1, 1)
    end

    test "can mismatch literal expressions" do
      refute Patch.Macro.match?(1, 2)
    end

    test "can match wildcards" do
      assert Patch.Macro.match?(_, 1)
    end

    test "can match multiple wildcards" do
      assert Patch.Macro.match?({_, _}, {1, 2})
    end

    test "can match pins" do
     x = 1
     assert Patch.Macro.match?(^x, 1)
    end

    test "can mismatch pins" do
      x = 1
      refute Patch.Macro.match?(^x, 2)
    end

    test "can match variables, but does not bind them" do
      x = :unbound
      assert Patch.Macro.match?(x, 1)
      assert x == :unbound
    end

    test "can match unused variables" do
      assert Patch.Macro.match?(_x, 1)
    end

    test "can match a mix of used and unused variabled, but does not bind them" do
      x = :unbound
      assert Patch.Macro.match?({x, _y}, {1, 2})
      assert x == :unbound
    end

    test "functionality works in arbitrarily complex expressions" do
      x = 1
      assert Patch.Macro.match?([^x, y, _, %{a: 1}], [1, 2, 3, %{a: 1, b: 2}])
    end
  end

  describe "match/2" do
    test "can match literal expressions" do
      assert Patch.Macro.match(1, 1)
    end

    test "raise MatchError on literal expressions mismatch" do
      assert_raise MatchError, "no match of right hand side value: 2", fn ->
        Patch.Macro.match(1, 2)
      end
    end

    test "can match wildcards" do
      assert Patch.Macro.match(_, 1)
    end

    test "can match multiple wildcards" do
      assert Patch.Macro.match({_, _}, {1, 2})
    end

    test "can match pins" do
     x = 1
     assert Patch.Macro.match(^x, 1)
    end

    test "raise MatchError on mismatch pins" do
      x = 1

      assert_raise MatchError, "no match of right hand side value: 2", fn ->
        Patch.Macro.match(^x, 2)
      end
    end

    test "can match variables and binds them" do
      assert Patch.Macro.match(x, 1)
      assert x == 1
    end

    test "can match unused variables" do
      assert Patch.Macro.match(_x, 1)
    end

    test "can match a mix of used and unused variabled" do
      assert Patch.Macro.match({x, _y}, {1, 2})
      assert x == 1
    end

    test "functionality works in arbitrarily complex expressions" do
      x = 1
      assert Patch.Macro.match([^x, y, _, %{a: 1}], [1, 2, 3, %{a: 1, b: 2}])
      assert y == 2
    end
  end
end
