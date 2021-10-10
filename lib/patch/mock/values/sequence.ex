defmodule Patch.Mock.Values.Sequence do
  @type t :: %__MODULE__{
          enumerable: Enumerable.t()
        }
  defstruct [:enumerable]

  @spec new(enumerable :: Enumerable.t()) :: t()
  def new(enumerable) do
    %__MODULE__{enumerable: enumerable}
  end

  @spec next(sequence :: t(), arguments :: [term()]) :: {:ok, t(), term()} | :error
  def next(%__MODULE__{enumerable: []} = sequence, _arguments) do
    {:ok, sequence, nil}
  end

  def next(%__MODULE__{enumerable: [last]} = sequence, _arguments) do
    {:ok, sequence, last}
  end

  def next(%__MODULE__{} = sequence, _arguments) do
    {[value], rest} = Enum.split(sequence.enumerable, 1)
    sequence = %__MODULE__{sequence | enumerable: rest}

    {:ok, sequence, value}
  end
end
