defmodule Patch.Mock do
  alias Patch.Mock

  @spec history(module :: module) :: Mock.History.t()
  def history(module) do
    Mock.Server.history(module)
  end

  @spec module(module :: module(), options :: [Mock.Server.option()]) :: {:ok, pid()} | {:error, term()}
  def module(module, options \\ []) do
    case Mock.Supervisor.start_child(module, options) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        {:ok, pid}

      {:error, _} = error ->
        error
    end
  end

  @spec returns(module :: module(), name :: atom(), value :: Mock.Value.t()) :: :ok
  def returns(module, name, value) do
    Mock.Server.register(module, name, value)
  end
end
