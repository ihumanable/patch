defmodule Patch.Test.User.SpyTest do
  use ExUnit.Case
  use Patch

  alias Patch.Test.Support.User.Spy

  describe "spy/1" do
    test "are transparent to the caller" do
      assert Spy.example(:test_argument_1) == {:original, :test_argument_1}

      spy(Spy)

      assert Spy.example(:test_argument_2) == {:original, :test_argument_2}
    end

    test "allows for assert_called" do
      assert Spy.example(:test_argument) == {:original, :test_argument}

      spy(Spy)

      assert Spy.example(:test_argument) == {:original, :test_argument}

      assert_called Spy.example(:test_argument)
    end

    test "raises MissingCall for assert_called that have not occurred" do
      assert Spy.example(:test_argument_1) == {:original, :test_argument_1}

      spy(Spy)

      assert Spy.example(:test_argument_2) == {:original, :test_argument_2}

      assert_raise Patch.MissingCall, fn ->
        # This call happened before the spy was applied
        assert_called Spy.example(:test_argument_1)
      end
    end

    test "allows for exact assert_called" do
      assert Spy.example(:test_argument_1) == {:original, :test_argument_1}

      spy(Spy)

      assert Spy.example(:test_argument_2) == {:original, :test_argument_2}

      assert_called Spy.example(:test_argument_2)
    end

    test "allows for assert_called with wildcards" do
      assert Spy.example(:test_argument_1) == {:original, :test_argument_1}

      spy(Spy)

      assert Spy.example(:test_argument_2) == {:original, :test_argument_2}

      assert_called Spy.example(_)
    end

    test "raises MissingCall if no calls have occurred on assert_called with wildcard" do
      assert Spy.example(:test_argument) == {:original, :test_argument}

      spy(Spy)

      assert_raise Patch.MissingCall, fn ->
        assert_called Spy.example(_)
      end
    end

    test "allows for refute_called" do
      assert Spy.example(:test_argument_1) == {:original, :test_argument_1}

      spy(Spy)

      assert Spy.example(:test_argument_2) == {:original, :test_argument_2}

      # This call happened before the spy was applied
      refute_called Spy.example(:test_argument_1)
    end

    test "raises UnexpectedCall for refute_called that have occurred" do
      assert Spy.example(:test_argument_1) == {:original, :test_argument_1}

      spy(Spy)

      assert Spy.example(:test_argument_2) == {:original, :test_argument_2}

      assert_raise Patch.UnexpectedCall, fn ->
        refute_called Spy.example(:test_argument_2)
      end
    end

    test "allows for refute_called with wildcards" do
      assert Spy.example(:test_argument) == {:original, :test_argument}

      spy(Spy)

      refute_called Spy.example(_)
    end

    test "raises UnexpectedCall for refute_called with wildcards if any call to the spy has occurred" do
      assert Spy.example(:test_argument_1) == {:original, :test_argument_1}

      spy(Spy)

      assert Spy.example(:test_argument_2) == {:original, :test_argument_2}

      assert_raise Patch.UnexpectedCall, fn ->
        refute_called Spy.example(_)
      end
    end
  end
end
