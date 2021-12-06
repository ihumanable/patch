defmodule Patch.Test.Support.User.Patch.GenServerExample do
  use GenServer

  ## Client

  def start_link(options \\ []) do
    options = Keyword.put_new(options, :name, __MODULE__)
    GenServer.start_link(__MODULE__, :ok, options)
  end

  def a(server \\ __MODULE__, argument) do
    GenServer.call(server, {:a, argument})
  end

  def b(server \\ __MODULE__, argument) do
    GenServer.call(server, {:b, argument})
  end

  def c(server \\ __MODULE__, argument) do
    GenServer.call(server, {:c, argument})
  end

  ## Server

  def init(:ok) do
    {:ok, []}
  end

  def handle_call({:a, argument}, _from, state) do
    {:reply, {:original, argument}, [{:a, argument} | state]}
  end

  def handle_call({:b, argument}, _from, state) do
    {:reply, {:original, argument}, [{:b, argument} | state]}
  end

  def handle_call({:c, argument}, _from, state) do
    {:reply, {:original, argument}, [{:c, argument} | state]}
  end
end
