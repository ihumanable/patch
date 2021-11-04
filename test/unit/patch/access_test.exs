defmodule Patch.Test.Unit.Patch.AccessTest do
  use ExUnit.Case
  use Patch

  alias Patch.Test.Support.Unit.Access, as: Target

  describe "fetch/2" do
    test "works with a struct" do
      target = %Target{value: :test}

      assert Patch.Access.fetch(target, [:value]) == {:ok, :test}
    end

    test "works with nested structs" do
      target = %Target{value: %Target.Inner{value: :test}}

      assert Patch.Access.fetch(target, [:value, :value]) == {:ok, :test}
    end

    test "works with maps" do
      target = %{key: :test}

      assert Patch.Access.fetch(target, [:key]) == {:ok, :test}
    end

    test "works with nested maps" do
      target = %{key: %{key: :test}}

      assert Patch.Access.fetch(target, [:key, :key]) == {:ok, :test}
    end

    test "works with mix of maps and structs" do
      target = %{key: %Target{value: %{key: %Target.Inner{value: :test}}}}

      assert Patch.Access.fetch(target, [:key, :value, :key, :value]) == {:ok, :test}
    end

    test "works on non-terminal keys" do
      target_value = %{key: %Target.Inner{value: :test}}

      target = %{key: %Target{value: target_value}}

      assert Patch.Access.fetch(target, [:key, :value]) == {:ok, target_value}
    end

    test "keys not found return :error" do
      target = %{outer: %{inner: :test}}

      assert Patch.Access.fetch(target, [:missing]) == :error
      assert Patch.Access.fetch(target, [:outer, :missing]) == :error
    end
  end

  describe "get/2,3" do
    test "works with a struct" do
      target = %Target{value: :test}

      assert Patch.Access.get(target, [:value]) == :test
    end

    test "works with nested structs" do
      target = %Target{value: %Target.Inner{value: :test}}

      assert Patch.Access.get(target, [:value, :value]) == :test
    end

    test "works with maps" do
      target = %{key: :test}

      assert Patch.Access.get(target, [:key]) == :test
    end

    test "works with nested maps" do
      target = %{key: %{key: :test}}

      assert Patch.Access.get(target, [:key, :key]) == :test
    end

    test "works with mix of maps and structs" do
      target = %{key: %Target{value: %{key: %Target.Inner{value: :test}}}}

      assert Patch.Access.get(target, [:key, :value, :key, :value]) == :test
    end

    test "works on non-terminal keys" do
      target_value = %{key: %Target.Inner{value: :test}}

      target = %{key: %Target{value: target_value}}

      assert Patch.Access.get(target, [:key, :value]) == target_value
    end

    test "keys not found returns default" do
      target = %{outer: %{inner: :test}}

      refute Patch.Access.get(target, [:missing])
      refute Patch.Access.get(target, [:outer, :missing])
    end

    test "default can be customized" do
      target = %{outer: %{inner: :test}}

      assert Patch.Access.get(target, [:missing], :custom_default) == :custom_default
      assert Patch.Access.get(target, [:outer, :missing], :custom_default) == :custom_default
    end
  end

  describe "put/2" do
    test "works with a struct" do
      target = %Target{value: :test}
      expected = %Target{value: :updated}

      assert Patch.Access.put(target, [:value], :updated) == expected
    end

    test "works with nested structs" do
      target = %Target{value: %Target.Inner{value: :test}}
      expected = %Target{value: %Target.Inner{value: :updated}}

      assert Patch.Access.put(target, [:value, :value], :updated) == expected
    end

    test "works with maps" do
      target = %{key: :test}
      expected = %{key: :updated}

      assert Patch.Access.put(target, [:key], :updated) == expected
    end

    test "works with nested maps" do
      target = %{key: %{key: :test}}
      expected = %{key: %{key: :updated}}

      assert Patch.Access.put(target, [:key, :key], :updated) == expected
    end

    test "works with mix of maps and structs" do
      target = %{key: %Target{value: %{key: %Target.Inner{value: :test}}}}
      expected = %{key: %Target{value: %{key: %Target.Inner{value: :updated}}}}

      assert Patch.Access.put(target, [:key, :value, :key, :value], :updated) == expected
    end

    test "works on non-terminal keys" do
      target = %{key: %Target{value: %{key: %Target.Inner{value: :test}}}}
      expected = %{key: %Target{value: :updated}}

      assert Patch.Access.put(target, [:key, :value], :updated) == expected
    end
  end

end
