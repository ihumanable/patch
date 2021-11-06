defmodule Patch.Test.Support.User.Inject.Target do
  use GenServer

  ## Client

  def start_link(multiplier) do
    GenServer.start_link(__MODULE__, multiplier)
  end

  def work(pid, argument) do
    GenServer.call(pid, {:work, argument})
  end

  ## Server

  def init(multiplier) do
    {:ok, multiplier}
  end

  def handle_call({:work, argument}, _from, multiplier) do
    {:reply, argument * multiplier, multiplier}
  end
end
