defmodule Patch.Listener do
  use GenServer

  @default_capture_replies true
  @default_timeout 5000

  @typedoc """
  Listeners are started with a tag so the listening process can differentiate
  between multiple listeners.
  """
  @type tag :: atom()

  @typedoc """
  Listeners listen to a target.
  """
  @type target :: GenServer.server() | nil

  @typedoc """
  Option to control whether or not to capture GenServer.call replies.

  Defaults to #{@default_capture_replies}
  """
  @type capture_replies_option :: {:capture_replies, boolean()}

  @typedoc """
  Option to control how long the listener should wait for GenServer.call

  Value is either the number of milliseconds to wait or the `:infinity` atom.

  If `capture_replies` is set to false this setting has no effect.

  Defaults to #{@default_timeout}
  """
  @type timeout_option :: {:timeout, timeout()}

  @typedoc """
  Sum-type of all valid options
  """
  @type option :: capture_replies_option() | timeout_option()

  @type t :: %__MODULE__{
          capture_replies: boolean(),
          recipient: pid(),
          tag: atom(),
          target: pid(),
          timeout: timeout()
        }
  defstruct [:capture_replies, :recipient, :tag, :target, :timeout]

  ## Client

  def child_spec(args) do
    recipient = Keyword.fetch!(args, :recipient)
    tag = Keyword.fetch!(args, :tag)
    target = Keyword.fetch!(args, :target)
    options = Keyword.get(args, :options, [])

    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [recipient, tag, target, options]},
      restart: :temporary
    }
  end

  @spec start_link(recipient :: atom(), tag :: tag(), target :: target(), [option()]) ::
          {:ok, pid()} | {:error, :not_found}
  def start_link(recipient, tag, target, options \\ [])

  def start_link(recipient, tag, target, options) when is_pid(target) or is_nil(target) do
    capture_replies = Keyword.get(options, :capture_replies, @default_capture_replies)
    timeout = Keyword.get(options, :timeout, @default_timeout)

    state = %__MODULE__{
      capture_replies: capture_replies,
      recipient: recipient,
      tag: tag,
      target: target,
      timeout: timeout
    }

    GenServer.start_link(__MODULE__, state)
  end

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

  def target(listener) do
    GenServer.call(listener, {__MODULE__, :target})
  end

  ## Server

  @spec init(t()) :: {:ok, t()}
  def init(%__MODULE__{} = state) do
    if is_pid(state.target) do
      Process.monitor(state.target)
    end

    {:ok, state}
  end

  def handle_call({__MODULE__, :target}, _from, state) do
    {:reply, state.target, state}
  end

  def handle_call(message, from, %__MODULE__{target: nil} = state) do
    report(state, {GenServer, :call, message, from})
    report(state, {:EXIT, :no_listener_target})
    Process.exit(self(), :no_listener_target)
  end

  def handle_call(message, from, %__MODULE__{capture_replies: false} = state) do
    report(state, {GenServer, :call, message, from})
    forward(state, {:"$gen_call", from, message})
    {:noreply, state}
  end

  def handle_call(message, from, state) do
    report(state, {GenServer, :call, message, from})

    try do
      response = GenServer.call(state.target, message, state.timeout)
      report(state, {GenServer, :reply, response, from})
      {:reply, response, state}
    catch
      :exit, {reason, _call} ->
        report(state, {:EXIT, reason})
        Process.exit(self(), reason)
    end
  end

  def handle_cast(message, state) do
    report(state, {GenServer, :cast, message})
    GenServer.cast(state.target, message)
    {:noreply, state}
  end

  def handle_info({:DOWN, _, :process, pid, reason}, %__MODULE__{target: pid} = state) do
    report(state, {:DOWN, reason})
    {:stop, {:shutdown, {:DOWN, reason}}, state}
  end

  def handle_info(message, state) do
    report(state, message)
    forward(state, message)
    {:noreply, state}
  end

  ## Private

  @compile {:inline, report: 2}
  defp report(%__MODULE__{} = state, message) do
    send(state.recipient, {state.tag, message})
  end

  @compile {:inline, forward: 2}
  defp forward(%__MODULE__{target: nil}, _) do
    :ok
  end

  defp forward(%__MODULE__{} = state, message) do
    send(state.target, message)
  end
end
