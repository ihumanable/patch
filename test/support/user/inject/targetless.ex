defmodule Patch.Test.Support.User.Inject.Targetless do
  @moduledoc """
  In the scenarios this module is used in, target_pid is meant to be a pid that
  is not defined at init but is expected to be loaded after initialization.

  This module is used to test inject on part of the state that is nil
  """

  use GenServer

  defstruct [:target_pid]

  ## Client

  def start_link() do
    GenServer.start_link(__MODULE__, :ok)
  end

  def hello(pid) do
    GenServer.call(pid, :hello)
  end

  ## Server

  def init(:ok) do
    {:ok, %__MODULE__{}}
  end

  def handle_call(:hello, _from, %__MODULE__{} = state) do
    send(state.target_pid, :greetings)
    {:reply, :ok, state}
  end
end
