defmodule Patch.Mock do
  alias Patch.Mock


  @spec called?(module :: module(), name :: atom()) :: boolean()
  def called?(module, name) do
    module
    |> history()
    |> Mock.History.entries(:desc)
    |> Enum.any?(&match?({^name, _}, &1))
  end

  @spec called?(module :: module(), name :: atom(), arguments :: [term()]) :: boolean()
  def called?(module, name, arguments) do
    module
    |> history()
    |> Mock.History.entries(:desc)
    |> Enum.any?(fn
      {^name, recorded_arguments} ->
        arguments_compatible?(arguments, recorded_arguments)

      _ ->
        false
    end)
  end

  @spec expose(module :: module, exposes :: Mock.Code.exposes()) :: :ok | {:error, term()}
  def expose(module, exposes) do
    with {:ok, _} <- module(module, exposes: exposes) do
      Mock.Server.expose(module, exposes)
    end
  end

  @spec history(module :: module()) :: Mock.History.t()
  def history(module) do
    Mock.Server.history(module)
  end

  @spec module(module :: module(), options :: [Mock.Server.option()]) ::
          {:ok, pid()} | {:error, term()}
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

  @spec register(module :: module(), name :: atom(), value :: Mock.Value.t()) :: :ok
  def register(module, name, value) do
    Mock.Server.register(module, name, value)
  end

  @spec restore(module :: module()) :: :ok
  def restore(module) do
    Mock.Server.restore(module)
  end

  ## Private

  defp argument_compatible?({:_, _}) do
    true
  end

  defp argument_compatible?({same, same}) do
    true
  end

  defp argument_compatible?(_) do
    false
  end

  defp arguments_compatible?(required_arguments, recorded_arguments) do
    arguments_compatible?(
      required_arguments,
      Enum.count(required_arguments),
      recorded_arguments,
      Enum.count(recorded_arguments)
    )
  end

  defp arguments_compatible?(required_arguments, same, recorded_arguments, same) do
    required_arguments
    |> Enum.zip(recorded_arguments)
    |> Enum.all?(&argument_compatible?/1)
  end

  defp arguments_compatible?(_, _, _, _) do
    false
  end
end
