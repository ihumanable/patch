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
  Returns the number of times a matching call has been observed

  The call arguments support any valid patterns.

  This function uses the Mock's history to check, if the history is limited or disabled then calls
  that have happened may report back as never having happened.
  """
  @spec call_count(call :: Macro.t()) :: Macro.t()
  defmacro call_count(call) do
    quote do
      unquote(call)
      |> Patch.Mock.matches()
      |> Enum.count()
    end
  end

  @doc """
  Checks to see if the call has been observed.

  The call arguments support any valid patterns.

  This function uses the Mock's history to check, if the history is limited or disabled then calls
  that have happened may report back as never having happened.
  """
  @spec called?(call :: Macro.t()) :: Macro.t()
  defmacro called?(call) do
    {module, function, pattern} = Macro.decompose_call(call)

    quote do
      unquote(module)
      |> Patch.Mock.history()
      |> Patch.Mock.History.entries(:desc)
      |> Enum.any?(fn
        {unquote(function), arguments} ->
          Patch.Macro.match?(unquote(pattern), arguments)

        _ ->
          false
      end)
    end
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
  Decorates the history with whether or not the call in the history matches the provided call.

  Provided call arguments support any valid patterns.

  Returns the calls descending (newest first) as a two-tuple in the form

  `{boolean(), {atom(), [term()]}}`

  The first element indicates whether the call matches the provided call.

  The second element is a tuple of function name and arguments.

  This macro uses the Mock's history to check, if the history is limited or disabled then calls
  that have happened may report back as never having happened.
  """
  @spec match_history(call :: Macro.t()) :: Macro.t()
  defmacro match_history(call) do
    {module, function, pattern} = Macro.decompose_call(call)

    quote do
      unquote(module)
      |> Patch.Mock.history()
      |> Patch.Mock.History.entries(:desc)
      |> Enum.map(fn
        {unquote(function), arguments} = call ->
          {Patch.Macro.match?(unquote(pattern), arguments), call}

        call ->
          {false, call}
      end)
    end
  end

  @doc """
  Returns all the calls in the history that match the provided call.

  Provided call arguments support any valid patterns.

  Returns the calls descending (newest first) as the list of arguments in the call

  This macro uses the Mock's history to check, if the history is limited or disabled then calls
  that have happened may report back as never having happened.
  """
  @spec matches(call :: Macro.t()) :: Macro.t()
  defmacro matches(call) do
    quote do
      unquote(call)
      |> Patch.Mock.match_history()
      |> Enum.filter(&elem(&1, 0))
      |> Enum.map(fn {true, {_function, arguments}} -> arguments end)
    end
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
end
