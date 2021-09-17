defmodule Patch.Test.Support.Listener.Counter do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    {:ok, 0}
  end

  def handle_call({:sleep, millis}, _from, state) do
    Process.sleep(millis)
    {:reply, :ok, state}
  end

  def handle_call(:crash, _from, state) do
    {:stop, {:shutdown, :crash}, state}
  end

  def handle_call(:exit, _from, state) do
    {:stop, :normal, state}
  end

  def handle_call(:increment, _from, state) do
    {:reply, state + 1, state + 1}
  end

  def handle_call(:decrement, _from, state) do
    {:reply, state - 1, state - 1}
  end

  def handle_call(:value, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:deferred_value, from, state) do
    send(self(), {:deferred_value, from})
    {:noreply, state}
  end

  def handle_cast(:increment, state) do
    {:noreply, state + 1}
  end

  def handle_cast(:decrement, state) do
    {:noreply, state - 1}
  end

  def handle_info(:increment, state) do
    {:noreply, state + 1}
  end

  def handle_info(:decrement, state) do
    {:noreply, state - 1}
  end

  def handle_info({:deferred_value, from}, state) do
    GenServer.reply(from, state)
    {:noreply, state}
  end
end
