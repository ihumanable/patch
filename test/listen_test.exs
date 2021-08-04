defmodule Patch.Test.ListenTest do
  use ExUnit.Case
  use Patch

  alias Patch.Test.Support.Listener.Counter

  def start_anonymous_process(_) do
    counter = start_supervised!(Counter)
    {:ok, counter: counter}
  end

  def start_named_process(_) do
    counter = start_supervised!({Counter, [name: Counter]})
    {:ok, counter: counter}
  end

  describe "listen/3 with named process when messages sent to name" do
    setup [:start_named_process]

    test "recipient receives GenServer.call request" do
      listen(:counter, Counter)

      GenServer.call(Counter, :increment)

      assert_receive {:counter, {GenServer, :call, :increment}}
    end

    test "recipient receives GenServer.call reply" do
      listen(:counter, Counter)

      GenServer.call(Counter, :increment)

      assert_receive {:counter, {GenServer, :reply, 1}}
    end

    test "recipient receives GenServer.cast request" do
      listen(:counter, Counter)

      GenServer.cast(Counter, :increment)

      assert_receive {:counter, {GenServer, :cast, :increment}}
    end

    test "recipient receives messages" do
      listen(:counter, Counter)

      send(Counter, :increment)

      assert_receive {:counter, :increment}
    end

    test "listeners can stack" do
      listen(:counter_1, Counter)
      listen(:counter_2, Counter)

      send(Counter, :increment)

      assert_receive {:counter_1, :increment}
      assert_receive {:counter_2, :increment}
    end

    test "error when named process does not exists" do
      assert {:error, :not_found} == listen(:counter, UnknownProcess)
    end
  end

  describe "listen/3 with named process when messages sent to listener" do
    setup [:start_named_process]

    test "recipient receives GenServer.call request" do
      {:ok, listener} = listen(:counter, Counter)

      GenServer.call(listener, :increment)

      assert_receive {:counter, {GenServer, :call, :increment}}
    end

    test "recipient receives GenServer.call reply" do
      {:ok, listener} = listen(:counter, Counter)

      GenServer.call(listener, :increment)

      assert_receive {:counter, {GenServer, :reply, 1}}
    end

    test "recipient receives GenServer.cast request" do
      {:ok, listener} = listen(:counter, Counter)

      GenServer.cast(listener, :increment)

      assert_receive {:counter, {GenServer, :cast, :increment}}
    end

    test "recipient receives messages" do
      {:ok, listener} = listen(:counter, Counter)

      send(listener, :increment)

      assert_receive {:counter, :increment}
    end
  end

  describe "listen/3 with anonymous process" do
    setup [:start_anonymous_process]

    test "recipient receives GenServer.call request", ctx do
      {:ok, listener} = listen(:counter, ctx.counter)

      GenServer.call(listener, :increment)

      assert_receive {:counter, {GenServer, :call, :increment}}
    end

    test "recipient receives GenServer.call reply", ctx do
      {:ok, listener} = listen(:counter, ctx.counter)

      assert 1 == GenServer.call(listener, :increment)

      assert_receive {:counter, {GenServer, :reply, 1}}
    end

    test "recipient receives GenServer.cast request", ctx do
      {:ok, listener} = listen(:counter, ctx.counter)

      GenServer.cast(listener, :increment)

      assert_receive {:counter, {GenServer, :cast, :increment}}
    end

    test "recipient receives messages", ctx do
      {:ok, listener} = listen(:counter, ctx.counter)

      send(listener, :increment)

      assert_receive {:counter, :increment}
    end

    test "listeners can stack", ctx do
      {:ok, listener_1} = listen(:counter_1, ctx.counter)
      {:ok, listener_2} = listen(:counter_2, listener_1)

      send(listener_2, :increment)

      assert_receive {:counter_1, :increment}
      assert_receive {:counter_2, :increment}
    end
  end
end
