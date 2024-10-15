defmodule Patch.Mock.Server do
  use GenServer
  require Logger

  alias Patch.Mock
  alias Patch.Mock.Code
  alias Patch.Mock.Code.Freezer
  alias Patch.Mock.Code.Unit
  alias Patch.Mock.History
  alias Patch.Mock.Naming
  alias Patch.Mock.Value
  alias Patch.Mock.Values

  @default_history_limit :infinity

  @typedoc """
  Sum-type of all valid options
  """
  @type option :: Mock.option()

  @type t :: %__MODULE__{
          history: History.t(),
          mocks: %{atom() => term()},
          module: module(),
          options: [Code.option()],
          unit: Unit.t()
        }
  defstruct history: History.new(:infinity),
            mocks: %{},
            module: nil,
            options: [],
            unit: nil

  ## Client

  def child_spec(args) do
    module = Keyword.fetch!(args, :module)
    options = Keyword.get(args, :options, [])

    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [module, options]},
      restart: :temporary
    }
  end

  @spec start_link(module :: module(), options :: [Code.option() | option()]) ::
          {:ok, pid()} | {:error, {:already_started, pid()}}
  def start_link(module, options \\ [])

  def start_link(module, options) do
    name = Naming.server(module)

    {history_limit, options} = Keyword.pop(options, :history_limit, @default_history_limit)

    state = %__MODULE__{
      history: History.new(history_limit),
      module: module,
      options: options
    }

    Freezer.get(GenServer).start_link(__MODULE__, state, name: name)
  end

  @doc """
  Delegates a call to a mocked module through the server so it can optionally
  respond with a mock value.
  """
  @spec delegate(module :: module(), name :: atom(), arguments :: [term()]) :: term()
  def delegate(module, name, arguments) do
    server = Naming.server(module)

    result =
      with {:ok, value} <- Freezer.get(GenServer).call(server, {:delegate, name, arguments}) do
        {next, result} = value(value, arguments)
        :ok = Freezer.get(GenServer).call(server, {:register, name, value, next})

        case result do
          {:raise, exception} ->
            debug(module, name, arguments, "mock raised", exception)
            raise exception

          {:throw, value} ->
            debug(module, name, arguments, "mock threw", value)
            throw(value)

          _ ->
            result
        end
      end

    case result do
      {:ok, reply} ->
        debug(module, name, arguments, "mock returned", reply)
        reply

      :error ->
        original_module = Naming.original(module)
        result = apply(original_module, name, arguments)
        debug(module, name, arguments, "no matching mock, using original, which returned", result)
        result
    end
  end

  @spec expose(module :: module(), exposes :: Mock.exposes()) :: :ok | {:error, term()}
  def expose(module, exposes) do
    server = Naming.server(module)
    Freezer.get(GenServer).call(server, {:expose, exposes})
  end

  @doc """
  Retrieves the call history for a mock
  """
  @spec history(module :: module()) :: History.t()
  def history(module) do
    call(module, :history, &History.new/0)
  end

  @doc """
  Restores a module to its original state.
  """
  @spec restore(module :: module()) :: :ok
  def restore(module) do
    call(module, :restore, fn -> :ok end)
  end

  @doc """
  Restores a function in a module to its original state
  """
  @spec restore(module :: module(), name :: atom()) :: :ok
  def restore(module, name) do
    call(module, {:restore, name}, fn -> :ok end)
  end

  @doc """
  Registers a mock value to be returned whenever the specified function is
  called on the module.
  """
  @spec register(module :: module(), name :: atom(), value :: Mock.Value.t()) :: :ok
  def register(module, name, value) do
    server = Naming.server(module)
    Freezer.get(GenServer).call(server, {:register, name, value})
  end

  ## Server

  @spec init(t()) :: {:ok, t()}
  def init(%__MODULE__{} = state) do
    Process.flag(:trap_exit, true)

    case Mock.Code.module(state.module, state.options) do
      {:ok, unit} ->
        {:ok, %__MODULE__{state | unit: unit}}

      {:error, reason} ->
        {:stop, reason}

      other ->
        {:stop, other}
    end
  end

  def handle_call({:delegate, name, arguments}, _from, state) do
    state = record(state, name, arguments)

    {:reply, Map.fetch(state.mocks, name), state}
  end

  def handle_call({:expose, exposes}, _from, state) do
    current_exposes = Keyword.get(state.options, :exposes, :public)

    case do_expose(state, current_exposes, exposes) do
      {:ok, state} ->
        {:reply, :ok, state}

      error ->
        {:stop, error, error, state}
    end
  end

  def handle_call(:history, _from, state) do
    {:reply, state.history, state}
  end

  def handle_call(:restore, _from, state) do
    {:stop, {:shutdown, {:restore, do_restore(state)}}, :ok, state}
  end

  def handle_call({:restore, name}, _from, state) do
    {:reply, :ok, do_restore(state, name)}
  end

  def handle_call({:register, name, value}, _from, state) do
    {:reply, :ok, do_register(state, name, value)}
  end

  def handle_call({:register, name, value, next}, _from, state) do
    {:reply, :ok, do_register(state, name, value, next)}
  end

  def terminate(_, state) do
    do_restore(state)
  end

  ## Private

  @spec call(module :: module(), message :: term(), default :: term()) :: term()
  defp call(module, message, default) do
    server = Naming.server(module)

    try do
      Freezer.get(GenServer).call(server, message)
    catch
      :exit, {:noproc, _} ->
        default.()
    end
  end

  @spec debug(
          module :: module(),
          name :: atom(),
          arguments :: [term()],
          label :: String.t(),
          value :: term()
        ) :: :ok
  defp debug(module, name, arguments, label, value) do
    if Application.get_env(:patch, :debug, false) do
      argument_list =
        arguments
        |> Enum.map(&inspect/1)
        |> Enum.join(", ")

      message = "Patch :: #{inspect(module)}.#{name}(#{argument_list}) #{label} #{inspect(value)}"
      Logger.debug(message)
    end

    :ok
  end

  @spec do_expose(
          state :: t(),
          current_exposes :: Code.exposes(),
          desired_exposes :: Code.exposes()
        ) :: {:ok, t()} | {:error, term()}
  defp do_expose(%__MODULE__{} = state, same, same) do
    {:ok, state}
  end

  defp do_expose(%__MODULE__{} = state, _, exposes) do
    with :ok <- do_restore(state),
         {:ok, unit} <- Mock.Code.module(state.module, exposes: exposes) do
      {:ok, %__MODULE__{state | unit: unit}}
    end
  end

  @spec do_register(state :: t(), name :: atom(), value :: term()) :: t()
  defp do_register(%__MODULE__{} = state, name, %Values.Callable{} = value) do
    case Map.fetch(state.mocks, name) do
      {:ok, %Values.Callable{} = existing} ->
        stack = Values.CallableStack.new([value, existing])
        do_register(state, name, stack)

      {:ok, %Values.CallableStack{} = stack} ->
        do_register(state, name, Values.CallableStack.push(stack, value))

      _ ->
        %__MODULE__{state | mocks: Map.put(state.mocks, name, value)}
    end
  end

  defp do_register(%__MODULE__{} = state, name, value) do
    %__MODULE__{state | mocks: Map.put(state.mocks, name, value)}
  end

  @spec do_register(state :: t(), name :: atom(), old_value :: term(), new_value :: term()) :: t()
  defp do_register(%__MODULE__{} = state, _name, same, same) do
    state
  end

  defp do_register(%__MODULE__{} = state, name, _old_value, new_value) do
    do_register(state, name, new_value)
  end

  def do_restore(%__MODULE__{} = state) do
    Unit.restore(state.unit)
  end

  def do_restore(%__MODULE__{} = state, name) do
    %__MODULE__{state | mocks: Map.delete(state.mocks, name)}
  end

  @spec record(state :: t(), name :: atom(), arguments :: [term()]) :: t()
  defp record(%__MODULE__{} = state, :__info__, _) do
    # Elixir function dispatch calls `__info__` don't pollute the history with
    # it
    state
  end

  defp record(%__MODULE__{} = state, name, arguments) do
    %__MODULE__{state | history: History.put(state.history, name, arguments)}
  end

  @spec value(value :: Value.t(), arguments :: [term()]) ::
          {:ok, t(), term()} | {:raise, t(), term()} | {:throw, t(), term()} | :error
  defp value(value, arguments) do
    try do
      case Value.next(value, arguments) do
        {:ok, next, reply} ->
          {next, {:ok, reply}}

        :error ->
          next = Value.advance(value)
          {next, :error}
      end
    rescue
      exception ->
        next = Value.advance(value)
        {next, {:raise, exception}}
    catch
      :throw, thrown ->
        next = Value.advance(value)
        {next, {:throw, thrown}}
    end
  end
end
