defmodule Patch.Mock.Values.Sequence do
  @type t :: %__MODULE__{
          values: [term()]
        }
  defstruct [:values]

  @spec advance(sequence :: t()) :: t()
  def advance(%__MODULE__{values: []} = sequence) do
    sequence
  end

  def advance(%__MODULE__{values: [_]} = sequence) do
    sequence
  end

  def advance(%__MODULE__{values: [_ | rest]} = sequence) do
    %__MODULE__{sequence | values: rest}
  end

  @spec new(values :: [term()]) :: t()
  def new(values) do
    %__MODULE__{values: values}
  end

  @spec next(sequence :: t(), arguments :: [term()]) :: {:ok, t(), term()} | :error
  def next(%__MODULE__{values: []} = sequence, _arguments) do
    {:ok, sequence, nil}
  end

  def next(%__MODULE__{values: [last]} = sequence, _arguments) do
    {:ok, sequence, last}
  end

  def next(%__MODULE__{values: [head | rest]} = sequence, _arguments) do
    sequence = %__MODULE__{sequence | values: rest}
    {:ok, sequence, head}
  end
end
