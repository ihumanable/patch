defmodule Patch.Test.PatchTest do
  use ExUnit.Case
  use Patch

  alias Patch.Test.Support.Example

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

  test "patching an unknown function is a no-op" do
    patch(Example, :function_that_does_not_exist, :this_can_never_be_retrieved)

    assert_raise UndefinedFunctionError, fn ->
      apply(Example, :function_that_does_not_exist, [])
    end
  end

  test "non-sticky erlang modules can be patched" do
    patch(:cpu_sup, :avg1, :test_value)

    assert :cpu_sup.avg1() == :test_value
  end

  test "sticky erlang modules can be patched" do
    patch(:string, :is_empty, :test_value)

    assert :string.is_empty("test") == :test_value
  end
end
