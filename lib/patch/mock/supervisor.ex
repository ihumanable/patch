defmodule Patch.Mock.Supervisor do
  use DynamicSupervisor

  def start_link(_ \\ []) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def start_child(module, options) do
    DynamicSupervisor.start_child(
      __MODULE__,
      {Patch.Mock.Server, module: module, options: options}
    )
  end

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
