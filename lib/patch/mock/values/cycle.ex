defmodule Patch.Mock.Values.Cycle do
  @type t :: %__MODULE__{
          enumerable: Enumerable.t()
        }
  defstruct [:enumerable]

  @spec new(enumerable :: Enumerable.t()) :: t()
  def new(enumerable) do
    %__MODULE__{enumerable: enumerable}
  end

  @spec next(t(), arguments :: [term()]) :: {:ok, t(), term()} | :error
  def next(%__MODULE__{} = cycle, _arguments) do
    {[value], rest} = Enum.split(cycle.enumerable, 1)
    cycle = %__MODULE__{cycle | enumerable: rest ++ [value]}

    {:ok, cycle, value}
  end
end
