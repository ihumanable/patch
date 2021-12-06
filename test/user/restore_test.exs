defmodule Patch.Test.User.RestoreTest do
  use ExUnit.Case
  use Patch

  alias Patch.Test.Support.User.Restore
  alias Patch.Test.Support.User.Fake.Fake
  alias Patch.Test.Support.User.Fake.Real

  describe "restore/1" do
    test "patches can be restored to original functionality" do
      assert Restore.example() == :original

      patch(Restore, :example, :patched)
      assert Restore.example() == :patched

      restore(Restore)
      assert Restore.example() == :original
    end

    test "fakes can be restored to original functionality" do
      assert Real.example(:a) == {:real, {:example, :a}}

      fake(Real, Fake)
      assert Real.example(:a) == {:fake, {:example, :a}}

      restore(Real)
      assert Real.example(:a) == {:real, {:example, :a}}
    end

    test "restoring an unpatched module is a no-op" do
      assert Restore.example() == :original

      restore(Restore)
      assert Restore.example() == :original
    end
  end

  describe "restore/2" do
    test "functions can be restored" do
      assert Restore.example() == :original

      patch(Restore, :example, :patched)
      assert Restore.example() == :patched

      restore(Restore, :example)
      assert Restore.example() == :original
    end

    test "function restoration is isolated" do
      assert Restore.example() == :original
      assert Restore.other() == :original

      patch(Restore, :example, :patched)
      patch(Restore, :other, :patched)
      assert Restore.example() == :patched
      assert Restore.other() == :patched

      restore(Restore, :example)
      assert Restore.example() == :original
      assert Restore.other() == :patched
    end

    test "restoring works on stacked callables" do
      assert Restore.example() == :original

      patch(Restore, :example, :first)
      assert Restore.example() == :first

      patch(Restore, :example, :second)
      assert Restore.example() == :second

      restore(Restore, :example)
      assert Restore.example() == :original
    end
  end
end
