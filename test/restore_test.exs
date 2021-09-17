defmodule Patch.Test.RestoreTest do
  use ExUnit.Case
  use Patch

  alias Patch.Test.Support.Example
  alias Patch.Test.Support.Fake.Fake
  alias Patch.Test.Support.Fake.Real

  describe "restore/1" do
    test "patches can be restored to original functionality" do
      assert Example.double(7) == 14

      patch(Example, :double, :patched_result)

      assert Example.double(7) == :patched_result

      restore(Example)

      assert Example.double(9) == 18
    end

    test "fakes can be restored to original functionality" do
      assert Real.example(:a) == {:real, {:example, :a}}

      fake(Real, Fake)

      assert Real.example(:a) == {:fake, {:example, :a}}

      restore(Real)

      assert Real.example(:a) == {:real, {:example, :a}}
    end

    test "restoring an unpatched module is a no-op" do
      assert Example.double(6) == 12

      restore(Example)

      assert Example.double(8) == 16
    end
  end
end
