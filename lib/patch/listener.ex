defmodule Patch.Listener do
  use GenServer

  @default_timeout 5000

  @typedoc """
  Option to control how long the listener should wait for GenServer.call

  Value is either the number of milliseconds to wait or the `:infinity` atom.

  Defaults to #{@default_timeout}
  """
  @type timeout_option :: {:timeout, timeout()}

  @typedoc """
  Sum-type of all valid options
  """
  @type option :: timeout_option()

  @typedoc """
  Convenience type for list of options
  """
  @type options :: [option()]

  @type t :: %__MODULE__{
          recipient: pid(),
          tag: atom(),
          target: pid(),
          timeout: timeout()
        }
  defstruct [:recipient, :tag, :target, :timeout]

  ## Client

  def child_spec(args) do
    recipient = Keyword.fetch!(args, :recipient)
    tag = Keyword.fetch!(args, :tag)
    target = Keyword.fetch!(args, :target)
    options = Keyword.get(args, :options, [])

    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [recipient, tag, target, options]}
    }
  end

  @spec start_link(recipient :: atom(), tag :: atom(), target :: pid() | atom(), options()) ::
          {:ok, pid()} | {:error, :not_found}
  def start_link(recipient, tag, target, options \\ [])

  def start_link(recipient, tag, target, options) when is_atom(target) do
    case Process.whereis(target) do
      nil ->
        {:error, :not_found}

      pid ->
        true = Process.unregister(target)
        {:ok, listener} = start_link(recipient, tag, pid, options)
        Process.register(listener, target)

        {:ok, listener}
    end
  end

  def start_link(recipient, tag, target, options) when is_pid(target) do
    timeout = options[:timeout] || @default_timeout

    state = %__MODULE__{recipient: recipient, tag: tag, target: target, timeout: timeout}

    GenServer.start_link(__MODULE__, state)
  end

  def target(listener) do
    GenServer.call(listener, {__MODULE__, :target})
  end

  ## Server

  @spec init(t()) :: {:ok, t()}
  def init(%__MODULE__{} = state) do
    Process.monitor(state.target)
    {:ok, state}
  end

  def handle_call({__MODULE__, :target}, _from, state) do
    {:reply, state.target, state}
  end

  def handle_call(message, _from, state) do
    send(state.recipient, {state.tag, {GenServer, :call, message}})
    response = GenServer.call(state.target, message, state.timeout)
    send(state.recipient, {state.tag, {GenServer, :reply, response}})
    {:reply, response, state}
  end

  def handle_cast(message, state) do
    send(state.recipient, {state.tag, {GenServer, :cast, message}})
    GenServer.cast(state.target, message)
    {:noreply, state}
  end

  def handle_info({:DOWN, _, :process, pid, reason}, %__MODULE__{target: pid} = state) do
    {:stop, {:shutdown, {:target_down, reason}}, state}
  end

  def handle_info(message, state) do
    send(state.recipient, {state.tag, message})
    send(state.target, message)
    {:noreply, state}
  end
end
