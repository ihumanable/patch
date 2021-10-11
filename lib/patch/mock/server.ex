defmodule Patch.Mock.Server do
  use GenServer
  require Logger

  alias Patch.Mock
  alias Patch.Mock.Code
  alias Patch.Mock.History
  alias Patch.Mock.Naming
  alias Patch.Mock.Value

  @default_history_limit :infinity

  @type history_limit_option :: {:history_limit, non_neg_integer() | :infinity}

  @typedoc """
  Sum-type of all valid options
  """
  @type option :: history_limit_option()

  @type t :: %__MODULE__{
          abstract_form: [Code.form()],
          compiler_options: Code.compiler_options(),
          history: History.t(),
          mocks: %{atom() => term()},
          module: module(),
          options: [Code.option()],
          sticky?: boolean()
        }
  defstruct abstract_form: [],
            compiler_options: [],
            history: History.new(:infinity),
            mocks: %{},
            module: nil,
            options: [],
            sticky?: false

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

    GenServer.start_link(__MODULE__, state, name: name)
  end

  @doc """
  Delegates a call to a mocked module through the server so it can optionally
  respond with a mock value.
  """
  @spec delegate(module :: module(), name :: atom(), arguments :: [term()]) :: term()
  def delegate(module, name, arguments) do
    server = Naming.server(module)

    case GenServer.call(server, {:delegate, name, arguments}) do
      {:ok, reply} ->
        reply

      :error ->
        original_module = Naming.original(module)
        apply(original_module, name, arguments)
    end
  end

  @doc """
  Retrieves the call history for a mock
  """
  @spec history(module :: module()) :: History.t()
  def history(module) do
    server = Naming.server(module)
    GenServer.call(server, :history)
  end

  @doc """
  Restores a module to its original state.

  Can be called by module or by pid
  """
  @spec restore(pid :: pid()) :: :ok
  def restore(pid) when is_pid(pid) do
    GenServer.call(pid, :restore)
  end

  @spec restore(module :: module()) :: :ok
  def restore(module) do
    server = Naming.server(module)

    try do
      GenServer.call(server, :restore)
    catch
      :exit, {:noproc, _} ->
        :ok
    end
  end

  @doc """
  Registers a mock value to be returned whenever the specified function is
  called on the module.
  """
  @spec register(module :: module(), name :: atom(), value :: Mock.Value.t()) :: :ok
  def register(module, name, value) do
    server = Naming.server(module)
    GenServer.call(server, {:register, name, value})
  end

  ## Server

  @spec init(t()) :: {:ok, t()}
  def init(%__MODULE__{} = state) do
    Process.flag(:trap_exit, true)

    case Mock.Code.mock(state.module, state.options) do
      {:ok, abstract_form, sticky?, compiler_options} ->
        state = %__MODULE__{
          state
          | abstract_form: abstract_form,
            compiler_options: compiler_options,
            sticky?: sticky?
        }

        {:ok, state}

      {:error, reason} ->
        {:stop, reason}

      other ->
        {:stop, other}
    end
  end

  def handle_call({:delegate, name, arguments}, _from, state) do
    state = record(state, name, arguments)

    case value(state, name, arguments) do
      {:ok, state, value} ->
        {:reply, {:ok, value}, state}

      :error ->
        {:reply, :error, state}
    end
  end

  def handle_call(:history, _from, state) do
    {:reply, state.history, state}
  end

  def handle_call(:restore, _from, state) do
    {:stop, {:shutdown, {:restore, do_restore(state)}}, :ok, state}
  end

  def handle_call({:register, name, value}, _from, state) do
    {:reply, :ok, do_register(state, name, value)}
  end

  def terminate(_, state) do
    do_restore(state)
  end

  ## Private

  defp purge(%__MODULE__{} = state) do
    [
      &Naming.delegate/1,
      &Naming.facade/1,
      &Naming.original/1
    ]
    |> Enum.each(fn factory ->
      state.module
      |> factory.()
      |> Mock.Code.purge()
    end)
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

  @spec do_register(state :: t(), name :: atom(), value :: term()) :: t()
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
    purge(state)

    if state.sticky? do
      Mock.Code.stick_module(state.module)
    else
      Mock.Code.compile(state.abstract_form, state.compiler_options)
    end
  end

  @spec value(state :: t(), name :: atom(), arguments :: [term()]) :: {:ok, t(), term()} | :error
  defp value(state, name, arguments) do
    with {:ok, value} <- Map.fetch(state.mocks, name),
         {:ok, next, reply} <- Value.next(value, arguments) do
      {:ok, do_register(state, name, value, next), reply}
    end
  end
end
