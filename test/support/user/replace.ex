defmodule Patch.Test.Support.User.Replace do
  use GenServer

  defmodule Inner do
    @type t :: %__MODULE__{
      value: term()
    }
    defstruct [:value]
  end

  @type t :: %__MODULE__{
          value: term(),
          inner: Inner.t()
        }
  defstruct [:value, :inner]

  ## Client

  def start_link(value, options \\ []) do
    GenServer.start_link(__MODULE__, value, options)
  end

  ## Server

  def init(value) do
    state = %__MODULE__{value: value, inner: %Inner{value: value}}

    {:ok, state}
  end
end
