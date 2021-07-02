defmodule Patch.Test.FakeTest do
  use ExUnit.Case
  use Patch

  describe "fake/2" do
    test "replaces the original module with a fake module" do
      assert {:original, {:example, :a}} == Original.example(:a)

      fake(Original, Fake)

      assert {:fake, {:example, :a}} == Original.example(:a)
    end

    test "original is still available with through the real/1 function" do
      assert {:original, {:example, :a}} == Original.example(:a)

      fake(Original, Fake)

      assert {:original, {:example, :a}} == real(Original).example(:a)
    end

    test "fake module can delegate to the real module" do
      assert {:original, {:another_example, :a}} == Original.another_example(:a)

      fake(Original, Fake)

      assert {:fake, {:another_example, {:original, {:another_example, :a}}, :a}} == Original.another_example(:a)
    end

    test "attempting to use the real module before faking raises UndefinedFunctionError" do
      assert_raise UndefinedFunctionError, fn ->
        real(Original).example(:a)
      end
    end

    test "assert_called when call is present" do
      fake(Original, Fake)

      assert {:fake, {:example, :present}} == Original.example(:present)
      assert_called Original.example(:present)
    end

    test "assert_called raises when call is absent" do
      fake(Original, Fake)

      assert {:fake, {:example, :present}} == Original.example(:present)

      assert_raise Patch.MissingCall, fn ->
        assert_called Original.example(:absent)
      end
    end

    test "refute_called when call is present" do
      fake(Original, Fake)

      assert {:fake, {:example, :present}} == Original.example(:present)
      assert_raise Patch.UnexpectedCall, fn ->
        refute_called Original.example(:present)
      end
    end

    test "refute_called when call is absent" do
      fake(Original, Fake)

      assert {:fake, {:example, :present}} == Original.example(:present)
      refute_called Original.example(:absent)
    end

    test "assert_any_called when no calls have happened" do
      fake(Original, Fake)

      assert_raise Patch.MissingCall, fn ->
        assert_any_call Original, :example
      end
    end

    test "assert_any_called when calls have happened" do
      fake(Original, Fake)

      assert {:fake, {:example, :a}} == Original.example(:a)
      assert_any_call Original, :example
    end

    test "refute_any_called when no calls have happened" do
      fake(Original, Fake)

      refute_any_call Original, :example
    end

    test "refute_any_called when calls have happened" do
      fake(Original, Fake)

      assert {:fake, {:example, :a}} == Original.example(:a)
      assert_raise Patch.UnexpectedCall, fn ->
        refute_any_call Original, :example
      end
    end
  end
end
