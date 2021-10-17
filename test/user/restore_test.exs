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
end
