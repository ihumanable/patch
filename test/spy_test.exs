defmodule Patch.Test.SpyTest do
  use ExUnit.Case
  use Patch

  alias Patch.Test.Support.Example

  describe "spy/1" do
    test "are transparent to the caller" do
      assert Example.double(11) == 22

      spy(Example)

      assert Example.double(17) == 34
    end

    test "allows for assert_called" do
      assert Example.double(27) == 54

      spy(Example)

      assert Example.double(32) == 64

      assert_called Example.double(32)
    end

    test "raises MissingCall for assert_called that have not occurred" do
      assert Example.double(28) == 56

      spy(Example)

      assert Example.double(22) == 44

      assert_raise Patch.MissingCall, fn ->
        # This call happened before the spy was applied
        assert_called Example.double(28)
      end
    end

    test "allows for assert_called with wildcards" do
      assert Example.double(27) == 54

      spy(Example)

      assert Example.double(32) == 64

      assert_called Example.double(32)
    end

    test "raises MissingCall if no calls have occurred on assert_called with wildcard" do
      assert Example.double(31) == 62

      spy(Example)

      assert_raise Patch.MissingCall, fn ->
        assert_called Example.double(:_)
      end
    end

    test "allows for refute_called" do
      assert Example.double(19) == 38

      spy(Example)

      assert Example.double(41) == 82

      # This call happened before the spy was applied
      refute_called Example.double(19)
    end

    test "raises UnexpectedCall for refute_called that have occurred" do
      assert Example.double(27) == 54

      spy(Example)

      assert Example.double(45) == 90

      assert_raise Patch.UnexpectedCall, fn ->
        refute_called Example.double(45)
      end
    end

    test "allows for refute_called with wildcards" do
      assert Example.double(23)

      spy(Example)

      refute_called Example.double(:_)
    end

    test "raises UnexpectedCall for refute_called with wildcards if any call to the spy has occurred" do
      assert Example.double(13) == 26

      spy(Example)

      assert Example.double(37) == 74

      assert_raise Patch.UnexpectedCall, fn ->
        refute_called Example.double(:_)
      end
    end
  end
end
