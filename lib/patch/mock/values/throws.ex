defmodule Patch.Mock.Values.Throws do
  @type t :: %__MODULE__{
          value: term()
        }
  defstruct [:value]

  @spec advance(throws :: t()) :: t()
  def advance(%__MODULE__{} = throws) do
    throws
  end

  @spec new(throws :: term()) :: t()
  def new(throws) do
    %__MODULE__{value: throws}
  end

  @spec next(throws :: t(), arguments :: [term()]) :: none()
  def next(%__MODULE__{} = throws, _arguments) do
    throw throws.value
  end
end
