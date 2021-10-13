defmodule Patch.Test.User.Patch.ArityTest do
  use ExUnit.Case
  use Patch

  alias Patch.Test.Support.User.Patch.Arity

  describe "patch has no arity restrictions" do
    test "can patch a function of arity 0" do
      assert Arity.function_of_arity_0() == :original

      patch(Arity, :function_of_arity_0, :patched)

      assert Arity.function_of_arity_0() == :patched
    end

    test "can patch a function of arity 20" do
      assert {:original, _} = Arity.function_of_arity_20(:a, :b, :c, :d, :e, :f, :g, :h, :i, :j, :k, :l, :m, :n, :o, :p, :q, :r, :s, :t)

      patch(Arity, :function_of_arity_20, :patched)

      assert Arity.function_of_arity_20(:a, :b, :c, :d, :e, :f, :g, :h, :i, :j, :k, :l, :m, :n, :o, :p, :q, :r, :s, :t) == :patched
    end
  end


end
