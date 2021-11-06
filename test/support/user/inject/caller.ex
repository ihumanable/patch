defmodule Patch.Test.Support.User.Inject.Caller do
  use GenServer

  alias Patch.Test.Support.User.Inject.Target

  defstruct [:bonus, :target_pid]

  ## Client

  def start_link(bonus, multiplier) do
    GenServer.start_link(__MODULE__, {bonus, multiplier})
  end

  def calculate(pid, argument) do
    GenServer.call(pid, {:calculate, argument})
  end

  ## Server

  def init({bonus, multiplier}) do
    {:ok, target_pid} = Target.start_link(multiplier)

    {:ok, %__MODULE__{bonus: bonus, target_pid: target_pid}}
  end

  def handle_call({:calculate, argument}, _from, %__MODULE__{} = state) do
    multiplied = Target.work(state.target_pid, argument)
    {:reply, multiplied + state.bonus, state}
  end
end
