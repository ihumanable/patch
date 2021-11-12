defmodule Patch.Test.Support.User.Patch.Freezer do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, :ok)
  end

  def work(pid) do
    GenServer.call(pid, :work)
  end

  def init(:ok) do
    {:ok, nil}
  end

  def handle_call(:work, _from, state) do
    {:reply, :ok, state}
  end
end
