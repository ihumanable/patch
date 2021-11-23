defmodule Patch.Test.User.DeadlineTest do
  use ExUnit.Case
  use Patch

  alias Patch.Test.Support.User.Deadline

  setup do
    refute Deadline.get() == :expected

    on_exit(fn ->
      Deadline.clear()
    end)
  end

  def milliseconds(function) do
    {micros, _} = :timer.tc(function)
    System.convert_time_unit(micros, :microsecond, :millisecond)
  end

  describe "deadline/3" do
    test "returns the functions result if it executes within the deadline" do
      assert :expected == deadline(fn -> :expected end)
    end

    test "passes when the condition is already true" do
      Deadline.put(:expected)

      deadline(fn ->
        assert Deadline.get() == :expected
      end)
    end

    test "passing when already true incurs little or no time penalty" do
      Deadline.put(:expected)

      expected = 0

      actual = milliseconds(fn ->
        deadline(fn ->
          assert Deadline.get() == :expected
        end)
      end)

      assert_in_delta(expected, actual, 10)
    end

    test "passes when the condition becomes true within the deadline" do
      Deadline.delayed_put(:expected, 100)

      deadline(fn ->
        assert Deadline.get() == :expected
      end)
    end

    test "passing deadlines take approximately as long as the condition takes to become true" do
      expected = 100
      Deadline.delayed_put(:expected, expected)

      actual = milliseconds(fn ->
        deadline(fn ->
          assert Deadline.get() == :expected
        end)
      end)

      assert_in_delta(expected, actual, 10)
    end

    test "fails when the condition does not become true within the deadline" do
      assert_raise Patch.DeadlineException, fn ->
        deadline(fn ->
          assert Deadline.get() == :expected
        end, 50)
      end
    end

    test "failing deadlines take approximately as long as the stated deadline" do
      expected = 50

      actual = milliseconds(fn ->
        assert_raise Patch.DeadlineException, fn ->
          deadline(fn ->
            assert Deadline.get() == :expected
          end, expected)
        end
      end)

      assert_in_delta(expected, actual, 10)
    end

    test "fails when function only raises" do
      assert_raise Patch.DeadlineException, fn ->
        deadline(fn ->
          raise "This function always raises"
        end, 50)
      end
    end

    test "fails when function only throws" do
      assert_raise Patch.DeadlineException, fn ->
        deadline(fn ->
          throw :always_throws
        end, 50)
      end
    end

    test "fails when function takes too long" do
      assert_raise Patch.DeadlineException, fn ->
        deadline(fn ->
          Process.sleep(100)
          :ok
        end, 50)
      end
    end

    test "when function takes too long, execution is capped by the deadline" do
      expected = 50

      actual = milliseconds(fn ->
        assert_raise Patch.DeadlineException, fn ->
          deadline(fn ->
            Process.sleep(100)
            :ok
          end, expected)
        end
      end)

      assert_in_delta(expected, actual, 10)
    end
  end
end
