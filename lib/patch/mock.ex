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
  Given a list of expected arguments and actual arguments checks to see if the
  two lists are compatible.

  In the `expected_arguments` the wildcard atom, `:_` can be used to match any
  value.
  """
  @spec arguments_compatible?(expected_arguments :: [term()], actual_arguments :: [term()]) :: boolean()
  def arguments_compatible?(expected_arguments, actual_arguments) do
    do_arguments_compatible?(
      expected_arguments,
      Enum.count(expected_arguments),
      actual_arguments,
      Enum.count(actual_arguments)
    )
  end

  @doc """
  Returns the number of times the given name has been called in the given module with the given
  arguments.

  The arguments list can include the wildcard atom, `:_`, to match any argument in that position.

  This function uses the Mock's history to check, if the history is limited or disabled then calls
  that have happened may report back as never having happened.
  """
  @spec call_count(module :: module(), name :: atom(), expected_arguments :: [term()]) :: non_neg_integer()
  def call_count(module, name, expected_arguments) do
    module
    |> history()
    |> Mock.History.entries(:desc)
    |> Enum.filter(fn
      {^name, actual_arguments} ->
        arguments_compatible?(expected_arguments, actual_arguments)

      _ ->
        false
    end)
    |> Enum.count()
  end

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

  The arguments list can include the wildcard atom, `:_`, to match any argument in that position.

  This function uses the Mock's history to check, if the history is limited or disabled then calls
  that have happened may report back as never having happened.
  """
  @spec called?(module :: module(), name :: atom(), expected_arguments :: [term()]) :: boolean()
  def called?(module, name, expected_arguments) do
    module
    |> history()
    |> Mock.History.entries(:desc)
    |> Enum.any?(fn
      {^name, actual_arguments} ->
        arguments_compatible?(expected_arguments, actual_arguments)

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

  defp do_argument_compatible?({:_, _}) do
    true
  end

  defp do_argument_compatible?({same, same}) do
    true
  end

  defp do_argument_compatible?(_) do
    false
  end

  defp do_arguments_compatible?(expected_arguments, same, actual_arguments, same) do
    expected_arguments
    |> Enum.zip(actual_arguments)
    |> Enum.all?(&do_argument_compatible?/1)
  end

  defp do_arguments_compatible?(_, _, _, _) do
    false
  end
end
