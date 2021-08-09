defmodule Patch.Test.FakeTest do
  use ExUnit.Case
  use Patch

  describe "fake/2" do
    test "replaces the real module with a fake module" do
      assert {:real, {:example, :a}} == Real.example(:a)

      fake(Real, Fake)

      assert {:fake, {:example, :a}} == Real.example(:a)
    end

    test "real is still available with through the real/1 function" do
      assert {:real, {:example, :a}} == Real.example(:a)

      fake(Real, Fake)

      assert {:real, {:example, :a}} == real(Real).example(:a)
    end

    test "fake module can delegate to the real module" do
      assert {:real, {:delegate, :a}} == Real.delegate(:a)

      fake(Real, Fake)

      assert {:fake, {:real, {:delegate, :a}}} == Real.delegate(:a)
    end

    test "attempting to use the real module before faking raises UndefinedFunctionError" do
      assert_raise UndefinedFunctionError, fn ->
        real(Real).example(:a)
      end
    end

    test "assert_called when call is present" do
      fake(Real, Fake)

      assert {:fake, {:example, :present}} == Real.example(:present)
      assert_called Real.example(:present)
    end

    test "assert_called raises when call is absent" do
      fake(Real, Fake)

      assert {:fake, {:example, :present}} == Real.example(:present)

      assert_raise Patch.MissingCall, fn ->
        assert_called Real.example(:absent)
      end
    end

    test "refute_called when call is present" do
      fake(Real, Fake)

      assert {:fake, {:example, :present}} == Real.example(:present)

      assert_raise Patch.UnexpectedCall, fn ->
        refute_called Real.example(:present)
      end
    end

    test "refute_called when call is absent" do
      fake(Real, Fake)

      assert {:fake, {:example, :present}} == Real.example(:present)
      refute_called Real.example(:absent)
    end

    test "assert_any_called when no calls have happened" do
      fake(Real, Fake)

      assert_raise Patch.MissingCall, fn ->
        assert_any_call Real, :example
      end
    end

    test "assert_any_called when calls have happened" do
      fake(Real, Fake)

      assert {:fake, {:example, :a}} == Real.example(:a)
      assert_any_call Real, :example
    end

    test "refute_any_called when no calls have happened" do
      fake(Real, Fake)

      refute_any_call Real, :example
    end

    test "refute_any_called when calls have happened" do
      fake(Real, Fake)

      assert {:fake, {:example, :a}} == Real.example(:a)

      assert_raise Patch.UnexpectedCall, fn ->
        refute_any_call Real, :example
      end
    end
  end
end
