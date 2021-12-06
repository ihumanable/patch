defmodule Patch.Test.User.Patch.GenServerTest do
  use ExUnit.Case
  use Patch

  alias Patch.Test.Support.User.Patch.GenServerExample, as: Example

  describe "Patch GenServer Support" do
    test "can patch callbacks" do
      start_supervised(Example)

      assert Example.a(:a) == {:original, :a}
      assert Example.b(:b) == {:original, :b}
      assert Example.c(:c) == {:original, :c}

      patch(Example, :handle_call, fn {_message, argument}, _from, state -> {:reply, {:patched, argument}, state} end)

      assert Example.a(:a) == {:patched, :a}
      assert Example.b(:b) == {:patched, :b}
      assert Example.c(:c) == {:patched, :c}
    end

    test "can patch subset of callbacks with a single patch call" do
      start_supervised(Example)

      assert Example.a(:a) == {:original, :a}
      assert Example.b(:b) == {:original, :b}
      assert Example.c(:c) == {:original, :c}

      patch(Example, :handle_call, fn
        {:a, argument}, _from, state ->
          {:reply, {:patched, argument}, state}

        {:b, argument}, _from, state ->
          {:reply, {:patched, argument}, state}
      end)

      assert Example.a(:a) == {:patched, :a}
      assert Example.b(:b) == {:patched, :b}
      assert Example.c(:c) == {:original, :c}
    end

    test "can patch subset of callbacks with multiple patch calls" do
      start_supervised(Example)

      assert Example.a(:a) == {:original, :a}
      assert Example.b(:b) == {:original, :b}
      assert Example.c(:c) == {:original, :c}

      patch(Example, :handle_call, fn
        {:a, argument}, _from, state ->
          {:reply, {:patched, argument}, state}
      end)

      patch(Example, :handle_call, fn
        {:b, argument}, _from, state ->
          {:reply, {:patched, argument}, state}
      end)

      assert Example.a(:a) == {:patched, :a}
      assert Example.b(:b) == {:patched, :b}
      assert Example.c(:c) == {:original, :c}
    end

    test "can change how a callback handles state" do
      {:ok, pid} = start_supervised(Example)

      assert Example.a(:a) == {:original, :a}
      assert :sys.get_state(pid) == [{:a, :a}]

      patch(Example, :handle_call, fn
        {:a, argument}, _from, state ->
          {:reply, {:patched, argument}, [:patched | state]}
      end)

      assert Example.a(:a) == {:patched, :a}
      assert :sys.get_state(pid) == [:patched, {:a, :a}]
    end
  end
end
