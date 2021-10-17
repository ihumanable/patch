defmodule Patch.Mock do
  alias Patch.Mock
  alias Patch.Mock.Code

  @typedoc """
  What exposures should be made in a module.


  - `:public` will only expose the public functions
  - `:all` will expose both public and private functions
  - A list of exports can be provided, they will be added to the `:public` functions.
  """
  @type exposes :: :all | :public | Code.exports()

  @typedoc """
  The exposes option controls if any private functions should be exposed.

  The default is `:public`.
  """
  @type exposes_option :: {:exposes, exposes()}

  @typedoc """
  This history_limit option controls how large of a history a mock should store

  It defaults to `:infinity` which will store an unlimited history.
  """
  @type history_limit_option :: {:history_limit, non_neg_integer() | :infinity}

  @typedoc """
  Sum-type of all valid options
  """
  @type option :: exposes_option() | history_limit_option()


  @doc """
  Checks to see if a function with the given name has been called in the given module.

  This function uses the Mock's history to check, if the history is limited or disabled then calls
  that have happened may report back as never having happened.
  """
  @spec called?(module :: module(), name :: atom()) :: boolean()
  def called?(module, name) do
    module
    |> history()
    |> Mock.History.entries(:desc)
    |> Enum.any?(&match?({^name, _}, &1))
  end

  @doc """
  Checks to see if a fucntion with the given name has been called in the given module with the
  given arguments.

  The arguments list can include the wildcard atom, `:_` to match any argument in that position.

  This function uses the Mock's history to check, if the history is limited or disabled then calls
  tht have happened may report back as never having happened.
  """
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

  @doc """
  Expose private functions in a module.

  If the module is not already mocked, calling this function will mock it.
  """
  @spec expose(module :: module, exposes :: exposes()) :: :ok | {:error, term()}
  def expose(module, exposes) do
    with {:ok, _} <- module(module, exposes: exposes) do
      Mock.Server.expose(module, exposes)
    end
  end

  @doc """
  Gets the call history for a module.

  If the module is not already mocked, this function returns an empty new history.
  """
  @spec history(module :: module()) :: Mock.History.t()
  def history(module) do
    Mock.Server.history(module)
  end

  @doc """
  Mocks the given module.

  Mocking a module accepts two options, see the `t:option/0` type in this module for details.
  """
  @spec module(module :: module(), options :: [option()]) ::
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

  @doc """
  Registers a mock value for a function.

  If the module is not already mocked, this function will mock it with no private functions
  exposed.
  """
  @spec register(module :: module(), name :: atom(), value :: Mock.Value.t()) :: :ok
  def register(module, name, value) do
    with {:ok, _} <- module(module) do
      Mock.Server.register(module, name, value)
    end
  end

  @doc """
  Restores a module to pre-patch functionality.

  If the module is not already mocked, this function no-ops.
  """
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
