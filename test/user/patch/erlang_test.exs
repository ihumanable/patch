defmodule Patch.Test.User.Patch.ErlangTest do
  use ExUnit.Case
  use Patch

  describe "patching erlang modules" do
    test "non-sticky erlang modules can be patched" do
      patch(:erlang_unsticky, :example_function, :test_value)

      assert :erlang_unsticky.example_function() == :test_value
    end


    test "sticky erlang modules can be patched" do
      patch(:array, :new, :test_value)

      assert :array.new() == :test_value
    end

    test "sticky erlang modules with erlang builtin functions can be patched" do
      patch(:string, :is_empty, :test_value)

      assert :string.is_empty("test") == :test_value
    end
  end
end
