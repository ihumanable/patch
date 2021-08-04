defmodule Patch.Test.Support.Inject.Storage do
  use GenServer

  @type t :: %__MODULE__{
          store: map(),
          validator: pid() | nil,
          version: pos_integer()
        }
  defstruct store: %{}, validator: nil, version: 1

  ## Client

  def child_spec(options) do
    validator = Keyword.get(options, :validator)
    options = Keyword.drop(options, [:validator])

    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [validator, options]}
    }
  end

  def start_link(validator, options \\ []) do
    GenServer.start_link(__MODULE__, validator, options)
  end

  def get(storage, key) do
    GenServer.call(storage, {:get, key})
  end

  def put(storage, key, value) do
    GenServer.call(storage, {:put, key, value})
  end

  def version(storage) do
    GenServer.call(storage, :version)
  end

  ## Server

  def init(validator) do
    state = %__MODULE__{validator: validator}

    {:ok, state}
  end

  def handle_call({:get, key}, _from, %__MODULE__{} = state) do
    {:reply, Map.fetch(state.store, key), state}
  end

  def handle_call({:put, key, value}, _from, %__MODULE__{validator: nil} = state) do
    {:reply, :ok, do_put(state, key, value)}
  end

  def handle_call({:put, key, value}, _from, %__MODULE__{} = state) do
    case GenServer.call(state.validator, {:validate, key, value}) do
      :ok ->
        {:reply, :ok, do_put(state, key, value)}

      error ->
        {:reply, error, state}
    end
  end

  def handle_call(:version, _from, %__MODULE__{} = state) do
    {:reply, state.version, state}
  end

  ## Private

  defp do_put(%__MODULE__{} = state, key, value) do
    store = Map.put(state.store, key, value)
    version = state.version + 1

    %__MODULE__{state | store: store, version: version}
  end
end
