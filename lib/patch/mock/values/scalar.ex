defmodule Patch.Mock.Values.Scalar do
  @type t :: %__MODULE__{
          value: term()
        }
  defstruct [:value]

  @spec advance(scalar :: t()) :: t()
  def advance(%__MODULE__{} = scalar) do
    scalar
  end

  @spec new(scalar :: term()) :: t()
  def new(scalar) do
    %__MODULE__{value: scalar}
  end

  @spec next(scalar :: t(), arguments :: [term()]) :: {:ok, t(), term()} | :error
  def next(%__MODULE__{} = scalar, _arguments) do
    {:ok, scalar, scalar.value}
  end
end
