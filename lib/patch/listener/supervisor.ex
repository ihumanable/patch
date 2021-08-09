defmodule Patch.Listener.Supervisor do
  use DynamicSupervisor

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def start_child(recipient, tag, target, options) do
    DynamicSupervisor.start_child(
      __MODULE__,
      {Patch.Listener, recipient: recipient, tag: tag, target: target, options: options}
    )
  end

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
