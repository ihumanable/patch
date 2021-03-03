defmodule PatchTest do
  use ExUnit.Case
  use Patch

  describe "patch/3" do
    test "returns the provided mock" do
      assert Example.double(5) == 10

      patch(Example, :double, :patched_result)

      assert Example.double(5) == :patched_result
    end

    test "returns the result of calling the provided function" do
      assert Example.double(5) == 10

      tripler = &(&1 * 3)

      patch(Example, :double, tripler)

      assert Example.double(5) == 15
      assert Example.double(7) == 21
    end

    test "calls can be asserted" do
      patch(Example, :double, :patched_result)

      Example.double(:expected_argument)

      assert_called Example.double(:expected_argument)
    end

    test "calls that have not happened raise MissingCall when asserted" do
      patch(Example, :double, :patched_result)

      Example.double(:expected_argument)

      assert_raise Patch.MissingCall, fn ->
        assert_called Example.double(:other_argument)
      end
    end

    test "calls can have wildcard assertions" do
      patch(Example, :double, :patched_result)

      Example.double(:expected_argument)

      assert_called Example.double(:_)
    end

    test "uncalled patch raises MissingCall on wildcard assertion" do
      patch(Example, :double, :patched_result)

      assert_raise Patch.MissingCall, fn ->
        assert_called Example.double(:_)
      end
    end

    test "calls can be refuted" do
      patch(Example, :double, :patched_result)

      Example.double(:expected_argument)

      refute_called Example.double(:other_argument)
    end

    test "calls that have happened raise UnexpectedCall when refuted" do
      patch(Example, :double, :patched_result)

      Example.double(:expected_argument)

      assert_raise Patch.UnexpectedCall, fn ->
        refute_called Example.double(:expected_argument)
      end
    end

    test "calls can have wildcard refutes" do
      patch(Example, :double, :patched_result)

      refute_called Example.double(:_)
    end

    test "any call causes a wildcard refute to raise UnexpectedCall" do
      patch(Example, :double, :patched_result)

      Example.double(:expected_argument)

      assert_raise Patch.UnexpectedCall, fn ->
        refute_called Example.double(:_)
      end
    end

    test "functions of large arities can be patched" do
      patch(Example, :function_with_26_arguments, :patched_result)

      assert :patched_result ==
               Example.function_with_26_arguments(
                 :a,
                 :b,
                 :c,
                 :d,
                 :e,
                 :f,
                 :g,
                 :h,
                 :i,
                 :j,
                 :k,
                 :l,
                 :m,
                 :n,
                 :o,
                 :p,
                 :q,
                 :r,
                 :s,
                 :t,
                 :u,
                 :v,
                 :w,
                 :x,
                 :y,
                 :z
               )
    end
  end

  describe "restore/1" do
    test "patches can be restored to original functionality" do
      assert Example.double(7) == 14

      patch(Example, :double, :patched_result)

      assert Example.double(7) == :patched_result

      restore(Example)

      assert Example.double(9) == 18
    end

    test "restoring an unpatched module is a no-op" do
      assert Example.double(6) == 12

      restore(Example)

      assert Example.double(8) == 16
    end
  end

  describe "spy/1" do
    test "are transparent to the caller" do
      assert Example.double(11) == 22

      spy(Example)

      assert Example.double(17) == 34
    end

    test "allows for assert_called" do
      assert Example.double(27) == 54

      spy(Example)

      assert Example.double(32) == 64

      assert_called Example.double(32)
    end

    test "raises MissingCall for assert_called that have not occurred" do
      assert Example.double(28) == 56

      spy(Example)

      assert Example.double(22) == 44

      assert_raise Patch.MissingCall, fn ->
        # This call happened before the spy was applied
        assert_called Example.double(28)
      end
    end

    test "allows for assert_called with wildcards" do
      assert Example.double(27) == 54

      spy(Example)

      assert Example.double(32) == 64

      assert_called Example.double(32)
    end

    test "raises MissingCall if no calls have occurred on assert_called with wildcard" do
      assert Example.double(31) == 62

      spy(Example)

      assert_raise Patch.MissingCall, fn ->
        assert_called Example.double(:_)
      end
    end

    test "allows for refute_called" do
      assert Example.double(19) == 38

      spy(Example)

      assert Example.double(41) == 82

      # This call happened before the spy was applied
      refute_called Example.double(19)
    end

    test "raises UnexpectedCall for refute_called that have occurred" do
      assert Example.double(27) == 54

      spy(Example)

      assert Example.double(45) == 90

      assert_raise Patch.UnexpectedCall, fn ->
        refute_called Example.double(45)
      end
    end

    test "allows for refute_called with wildcards" do
      assert Example.double(23)

      spy(Example)

      refute_called Example.double(:_)
    end

    test "raises UnexpectedCall for refute_called with wildcards if any call to the spy has occurred" do
      assert Example.double(13) == 26

      spy(Example)

      assert Example.double(37) == 74

      assert_raise Patch.UnexpectedCall, fn ->
        refute_called Example.double(:_)
      end
    end
  end

  describe "assert_any_call/2" do
    test "does not raise if a patched function has a call of any arity (/1)" do
      patch(Example, :function_with_multiple_arities, :patched_result)

      assert :patched_result == Example.function_with_multiple_arities(1)

      assert_any_call Example, :function_with_multiple_arities
    end

    test "does not raise if a patched function has a call of any arity (/2)" do
      patch(Example, :function_with_multiple_arities, :patched_result)

      assert :patched_result == Example.function_with_multiple_arities(1, 2)

      assert_any_call Example, :function_with_multiple_arities
    end

    test "does not raise if a patched function has a call of any arity (/3)" do
      patch(Example, :function_with_multiple_arities, :patched_result)

      assert :patched_result == Example.function_with_multiple_arities(1, 2, 3)

      assert_any_call Example, :function_with_multiple_arities
    end

    test "does not raise if a spied module has a call of any arity (/1)" do
      spy(Example)

      assert {1, 1} == Example.function_with_multiple_arities(1)

      assert_any_call Example, :function_with_multiple_arities
    end

    test "does not raise if a spied module has a call of any arity (/2)" do
      spy(Example)

      assert {{1, 2}, 2} == Example.function_with_multiple_arities(1, 2)

      assert_any_call Example, :function_with_multiple_arities
    end

    test "does not raise if a spied module has a call of any arity (/3)" do
      spy(Example)

      assert {{1, 2, 3}, 3} == Example.function_with_multiple_arities(1, 2, 3)

      assert_any_call Example, :function_with_multiple_arities
    end

    test "raises if a patched function has no calls" do
      patch(Example, :function_with_multiple_arities, :patched_result)

      assert_raise Patch.MissingCall, fn ->
        assert_any_call Example, :function_with_multiple_arities
      end
    end

    test "raises if a spied module function has no calls" do
      spy(Example)

      assert_raise Patch.MissingCall, fn ->
        assert_any_call Example, :function_with_multiple_arities
      end
    end
  end

  describe "refute_any_call/2" do
    test "raises if a patched function has a call of any arity (/1)" do
      patch(Example, :function_with_multiple_arities, :patched_result)

      assert :patched_result == Example.function_with_multiple_arities(1)

      assert_raise Patch.UnexpectedCall, fn ->
        refute_any_call Example, :function_with_multiple_arities
      end
    end

    test "raises if a patched function has a call of any arity (/2)" do
      patch(Example, :function_with_multiple_arities, :patched_result)

      assert :patched_result == Example.function_with_multiple_arities(1, 2)

      assert_raise Patch.UnexpectedCall, fn ->
        refute_any_call Example, :function_with_multiple_arities
      end
    end

    test "raises if a patched function has a call of any arity (/3)" do
      patch(Example, :function_with_multiple_arities, :patched_result)

      assert :patched_result == Example.function_with_multiple_arities(1, 2, 3)

      assert_raise Patch.UnexpectedCall, fn ->
        refute_any_call Example, :function_with_multiple_arities
      end
    end

    test "raises if a spied module has a call of any arity (/1)" do
      spy(Example)

      assert {1, 1} == Example.function_with_multiple_arities(1)

      assert_raise Patch.UnexpectedCall, fn ->
        refute_any_call Example, :function_with_multiple_arities
      end
    end

    test "raises if a spied module has a call of any arity (/2)" do
      spy(Example)

      assert {{1, 2}, 2} == Example.function_with_multiple_arities(1, 2)

      assert_raise Patch.UnexpectedCall, fn ->
        refute_any_call Example, :function_with_multiple_arities
      end
    end

    test "raises if a spied module has a call of any arity (/3)" do
      spy(Example)

      assert {{1, 2, 3}, 3} == Example.function_with_multiple_arities(1, 2, 3)

      assert_raise Patch.UnexpectedCall, fn ->
        refute_any_call Example, :function_with_multiple_arities
      end
    end

    test "does not raise if a patched function has no calls" do
      patch(Example, :function_with_multiple_arities, :patched_result)
      refute_any_call Example, :function_with_multiple_arities
    end

    test "does not raise if a spied module function has no calls" do
      spy(Example)
      refute_any_call Example, :function_with_multiple_arities
    end
  end
end
