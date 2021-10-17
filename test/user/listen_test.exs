defmodule Patch.Test.User.ListenTest do
  use ExUnit.Case
  use Patch

  alias Patch.Test.Support.User.Listener.Counter

  def start_anonymous_gen_server(_) do
    counter = start_supervised!(Counter)
    {:ok, counter: counter}
  end

  def start_named_gen_server(_) do
    counter = start_supervised!({Counter, [name: Counter]})
    {:ok, counter: counter}
  end

  def start_named_process(_) do
    target = spawn(fn -> Process.sleep(:infinity) end)
    Process.register(target, Target)
    {:ok, target: target}
  end

  def start_anonymous_process(_) do
    target = spawn(fn -> Process.sleep(:infinity) end)
    {:ok, target: target}
  end

  def start_named_exitable_process(_) do
    target =
      spawn(fn ->
        receive do
          :crash ->
            Process.exit(self(), {:shutdown, :crash})

          _ ->
            :ok
        end
      end)

    Process.register(target, Target)

    {:ok, target: target}
  end

  def start_anonymous_exitable_process(_) do
    target =
      spawn(fn ->
        receive do
          :crash ->
            Process.exit(self(), {:shutdown, :crash})

          _ ->
            :ok
        end
      end)

    {:ok, target: target}
  end

  describe "listen/3 with named GenServer when messages sent to name" do
    setup [:start_named_gen_server]

    test "recipient receives GenServer.call request" do
      listen(:counter, Counter)

      GenServer.call(Counter, :increment)

      assert_receive {:counter, {GenServer, :call, :increment, _}}
    end

    test "recipient receives GenServer.call reply" do
      listen(:counter, Counter)

      GenServer.call(Counter, :increment)

      assert_receive {:counter, {GenServer, :reply, 1, _}}
    end

    test "receipient can correlate calls and replies" do
      listen(:counter, Counter)

      GenServer.call(Counter, :increment)

      assert_receive {:counter, {GenServer, :call, :increment, from}}
      assert_receive {:counter, {GenServer, :reply, 1, ^from}}
    end

    test "recipient receives GenServer.call deferred reply" do
      listen(:counter, Counter)

      GenServer.call(Counter, :deferred_value)

      assert_receive {:counter, {GenServer, :reply, 0, _}}
    end

    test "recipient can correlate calls and deferred replies" do
      listen(:counter, Counter)

      GenServer.call(Counter, :deferred_value)

      assert_receive {:counter, {GenServer, :call, :deferred_value, from}}
      assert_receive {:counter, {GenServer, :reply, 0, ^from}}
    end

    test "listener call timeout is configurable" do
      {:ok, listener} = listen(:counter, Counter, timeout: 100)

      ref = Process.monitor(listener)

      assert :ok = GenServer.call(Counter, {:sleep, 50})

      try do
        GenServer.call(Counter, {:sleep, 200})
        flunk("Listener mediated call should have timed out")
      catch
        :exit, {reason, _call} ->
          assert reason == :timeout
      end

      assert_receive {:counter, {:EXIT, :timeout}}
      assert_receive {:DOWN, ^ref, :process, ^listener, :timeout}

      refute Process.alive?(listener)
    end

    test "listener reply capturing is configurable" do
      listen(:counter, Counter, capture_replies: false)

      GenServer.call(Counter, :increment)

      assert_receive {:counter, {GenServer, :call, :increment, _}}
      refute_receive {:counter, {GenServer, :reply, _, _}}
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

  describe "listen/3 with named GenServer when messages sent to listener" do
    setup [:start_named_gen_server]

    test "recipient receives GenServer.call request" do
      {:ok, listener} = listen(:counter, Counter)

      GenServer.call(listener, :increment)

      assert_receive {:counter, {GenServer, :call, :increment, _}}
    end

    test "recipient receives GenServer.call reply" do
      {:ok, listener} = listen(:counter, Counter)

      GenServer.call(listener, :increment)

      assert_receive {:counter, {GenServer, :reply, 1, _}}
    end

    test "recipient can correlate calls and replies" do
      {:ok, listener} = listen(:counter, Counter)

      GenServer.call(listener, :increment)

      assert_receive {:counter, {GenServer, :call, :increment, from}}
      assert_receive {:counter, {GenServer, :reply, 1, ^from}}
    end

    test "recipient receives GenServer.call deferred reply" do
      {:ok, listener} = listen(:counter, Counter)

      assert 0 == GenServer.call(listener, :deferred_value)

      assert_receive {:counter, {GenServer, :reply, 0, _}}
    end

    test "recipient can correlate calls and deferred replies" do
      {:ok, listener} = listen(:counter, Counter)

      GenServer.call(listener, :deferred_value)

      assert_receive {:counter, {GenServer, :call, :deferred_value, from}}
      assert_receive {:counter, {GenServer, :reply, 0, ^from}}
    end

    test "listener call timeout is configurable" do
      {:ok, listener} = listen(:counter, Counter, timeout: 100)

      ref = Process.monitor(listener)

      assert :ok = GenServer.call(Counter, {:sleep, 50})

      try do
        GenServer.call(listener, {:sleep, 200})
        flunk("Listener mediated call should have timed out")
      catch
        :exit, {reason, _call} ->
          assert reason == :timeout
      end

      assert_receive {:counter, {:EXIT, :timeout}}
      assert_receive {:DOWN, ^ref, :process, ^listener, :timeout}

      refute Process.alive?(listener)
    end

    test "listener reply capturing is configurable" do
      {:ok, listener} = listen(:counter, Counter, capture_replies: false)

      GenServer.call(listener, :increment)

      assert_receive {:counter, {GenServer, :call, :increment, _}}
      refute_receive {:counter, {GenServer, :reply, _, _}}
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

  describe "listen/3 with GenServer process" do
    setup [:start_anonymous_gen_server]

    test "recipient receives GenServer.call request", ctx do
      {:ok, listener} = listen(:counter, ctx.counter)

      GenServer.call(listener, :increment)

      assert_receive {:counter, {GenServer, :call, :increment, _}}
    end

    test "recipient receives GenServer.call reply", ctx do
      {:ok, listener} = listen(:counter, ctx.counter)

      assert 1 == GenServer.call(listener, :increment)

      assert_receive {:counter, {GenServer, :reply, 1, _}}
    end

    test "recipient can correlate calls and replies", ctx do
      {:ok, listener} = listen(:counter, ctx.counter)

      assert 1 == GenServer.call(listener, :increment)

      assert_receive {:counter, {GenServer, :call, :increment, from}}
      assert_receive {:counter, {GenServer, :reply, 1, ^from}}
    end

    test "recipient receives GenServer.call deferred reply", ctx do
      {:ok, listener} = listen(:counter, ctx.counter)

      assert 0 == GenServer.call(listener, :deferred_value)

      assert_receive {:counter, {GenServer, :reply, 0, _}}
    end

    test "recipient can correlate calls and deferred replies", ctx do
      {:ok, listener} = listen(:counter, ctx.counter)

      assert 0 == GenServer.call(listener, :deferred_value)

      assert_receive {:counter, {GenServer, :call, :deferred_value, from}}
      assert_receive {:counter, {GenServer, :reply, 0, ^from}}
    end

    test "listener call timeout is configurable", ctx do
      {:ok, listener} = listen(:counter, ctx.counter, timeout: 100)

      ref = Process.monitor(listener)

      assert :ok = GenServer.call(listener, {:sleep, 50})

      try do
        GenServer.call(listener, {:sleep, 200}, 200)
        flunk("Listener mediated call should have timed out")
      catch
        :exit, {reason, _call} ->
          assert reason == :timeout
      end

      assert_receive {:counter, {:EXIT, :timeout}}
      assert_receive {:DOWN, ^ref, :process, ^listener, :timeout}

      refute Process.alive?(listener)
    end

    test "listener reply capturing is configurable", ctx do
      {:ok, listener} = listen(:counter, ctx.counter, capture_replies: false)

      GenServer.call(listener, :increment)

      assert_receive {:counter, {GenServer, :call, :increment, _}}
      refute_receive {:counter, {GenServer, :reply, _, _}}
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

  describe "listen/3 when named GenServer exits" do
    setup [:start_named_gen_server]

    test "recipient is notified and listener exits on observed normal exit" do
      {:ok, listener} = listen(:counter, Counter)

      ref = Process.monitor(listener)

      try do
        GenServer.call(Counter, :exit)
        flunk("GenServer failed to exit")
      catch
        :exit, {reason, _call} ->
          assert reason == :normal
      end

      assert_receive {:counter, {GenServer, :call, :exit, _}}
      assert_receive {:counter, {:EXIT, :normal}}
      assert_receive {:DOWN, ^ref, :process, ^listener, :normal}

      refute Process.alive?(listener)
    end

    test "recipient is notified and listener exits on out-of-band normal exit", ctx do
      {:ok, listener} = listen(:counter, Counter)

      ref = Process.monitor(listener)

      try do
        GenServer.call(ctx.counter, :exit)
        flunk("GenServer failed to exit")
      catch
        :exit, {reason, _call} ->
          assert reason == :normal
      end

      refute_receive {:counter, {GenServer, :call, :exit}}
      assert_receive {:counter, {:DOWN, :normal}}
      assert_receive {:DOWN, ^ref, :process, ^listener, {:shutdown, {:DOWN, :normal}}}

      refute Process.alive?(listener)
    end

    test "recipient is notified and listener exits on observed crash" do
      {:ok, listener} = listen(:counter, Counter)

      ref = Process.monitor(listener)

      try do
        GenServer.call(Counter, :crash)
        flunk("GenServer failed to crash")
      catch
        :exit, {reason, _call} ->
          assert reason == {:shutdown, :crash}
      end

      assert_receive {:counter, {GenServer, :call, :crash, _}}
      assert_receive {:counter, {:EXIT, {:shutdown, :crash}}}
      assert_receive {:DOWN, ^ref, :process, ^listener, {:shutdown, :crash}}

      refute Process.alive?(listener)
    end

    test "recipient is notified and listener exits on out-of-band crash", ctx do
      {:ok, listener} = listen(:counter, Counter)

      ref = Process.monitor(listener)

      try do
        GenServer.call(ctx.counter, :crash)
        flunk("GenServer failed to crash")
      catch
        :exit, {reason, _call} ->
          assert reason == {:shutdown, :crash}
      end

      refute_receive {:counter, {GenServer, :call, :crash, _}}
      assert_receive {:counter, {:DOWN, {:shutdown, :crash}}}
      assert_receive {:DOWN, ^ref, :process, ^listener, {:shutdown, {:DOWN, {:shutdown, :crash}}}}

      refute Process.alive?(listener)
    end
  end

  describe "listen/3 when anonymous GenServer exits" do
    setup [:start_anonymous_gen_server]

    test "recipient is notified and listener exits on observed normal exit", ctx do
      {:ok, listener} = listen(:counter, ctx.counter)

      ref = Process.monitor(listener)

      try do
        GenServer.call(listener, :exit)
        flunk("GenServer failed to exit")
      catch
        :exit, {reason, _call} ->
          assert reason == :normal
      end

      assert_receive {:counter, {GenServer, :call, :exit, _}}
      assert_receive {:counter, {:EXIT, :normal}}
      assert_receive {:DOWN, ^ref, :process, ^listener, :normal}

      refute Process.alive?(listener)
    end

    test "recipient is notified and listener exits on out-of-band normal exit", ctx do
      {:ok, listener} = listen(:counter, ctx.counter)

      ref = Process.monitor(listener)

      try do
        GenServer.call(ctx.counter, :exit)
        flunk("GenServer failed to exit")
      catch
        :exit, {reason, _call} ->
          assert reason == :normal
      end

      refute_receive {:counter, {GenServer, :call, :exit}}
      assert_receive {:counter, {:DOWN, :normal}}
      assert_receive {:DOWN, ^ref, :process, ^listener, {:shutdown, {:DOWN, :normal}}}

      refute Process.alive?(listener)
    end

    test "recipient is notified and listener exits on observed crash", ctx do
      {:ok, listener} = listen(:counter, ctx.counter)

      ref = Process.monitor(listener)

      try do
        GenServer.call(listener, :crash)
        flunk("GenServer failed to crash")
      catch
        :exit, {reason, _call} ->
          assert reason == {:shutdown, :crash}
      end

      assert_receive {:counter, {GenServer, :call, :crash, _}}
      assert_receive {:counter, {:EXIT, {:shutdown, :crash}}}
      assert_receive {:DOWN, ^ref, :process, ^listener, {:shutdown, :crash}}

      refute Process.alive?(listener)
    end

    test "recipient is notified and listener exits on out-of-band crash", ctx do
      {:ok, listener} = listen(:counter, ctx.counter)

      ref = Process.monitor(listener)

      try do
        GenServer.call(ctx.counter, :crash)
        flunk("GenServer failed to crash")
      catch
        :exit, {reason, _call} ->
          assert reason == {:shutdown, :crash}
      end

      refute_receive {:counter, {GenServer, :call, :crash}}
      assert_receive {:counter, {:DOWN, {:shutdown, :crash}}}
      assert_receive {:DOWN, ^ref, :process, ^listener, {:shutdown, {:DOWN, {:shutdown, :crash}}}}

      refute Process.alive?(listener)
    end
  end

  describe "listen/3 with named process when messages sent to name" do
    setup [:start_named_process]

    test "recipient recieves message" do
      listen(:target, Target)

      send(Target, :test_message)

      assert_receive {:target, :test_message}
    end
  end

  describe "listen/3 with named process when messages sent to listener" do
    setup [:start_named_process]

    test "recipient receives message" do
      {:ok, listener} = listen(:target, Target)

      send(listener, :test_message)

      assert_receive {:target, :test_message}
    end
  end

  describe "listen/3 with anonymous process when messages sent to listener" do
    setup [:start_anonymous_process]

    test "recipient receives message", ctx do
      {:ok, listener} = listen(:target, ctx.target)

      send(listener, :test_message)

      assert_receive {:target, :test_message}
    end
  end

  describe "listen/3 when named process exits" do
    setup [:start_named_exitable_process]

    test "recipient is notified and listener exits on normal exit" do
      {:ok, listener} = listen(:target, Target)

      ref = Process.monitor(listener)

      send(Target, :test_message)

      assert_receive {:target, :test_message}
      assert_receive {:target, {:DOWN, :normal}}
      assert_receive {:DOWN, ^ref, :process, ^listener, {:shutdown, {:DOWN, :normal}}}

      refute Process.alive?(listener)
    end

    test "recipient is notified and listener exits on crash" do
      {:ok, listener} = listen(:target, Target)

      ref = Process.monitor(listener)

      send(Target, :crash)

      assert_receive {:target, :crash}
      assert_receive {:target, {:DOWN, {:shutdown, :crash}}}
      assert_receive {:DOWN, ^ref, :process, ^listener, {:shutdown, {:DOWN, {:shutdown, :crash}}}}

      refute Process.alive?(listener)
    end
  end

  describe "listen/3 when anonymous process exits" do
    setup [:start_anonymous_exitable_process]

    test "recipient is notified and listener exits on normal exit", ctx do
      {:ok, listener} = listen(:target, ctx.target)

      ref = Process.monitor(listener)

      send(listener, :test_message)

      assert_receive {:target, :test_message}
      assert_receive {:target, {:DOWN, :normal}}
      assert_receive {:DOWN, ^ref, :process, ^listener, {:shutdown, {:DOWN, :normal}}}

      refute Process.alive?(listener)
    end

    test "recipient is notified and listener exits on crash", ctx do
      {:ok, listener} = listen(:target, ctx.target)

      ref = Process.monitor(listener)

      send(listener, :crash)

      assert_receive {:target, :crash}
      assert_receive {:target, {:DOWN, {:shutdown, :crash}}}
      assert_receive {:DOWN, ^ref, :process, ^listener, {:shutdown, {:DOWN, {:shutdown, :crash}}}}

      refute Process.alive?(listener)
    end
  end
end
