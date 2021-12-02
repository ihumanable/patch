defmodule Patch.Mock.Values.Cycle do
  @type t :: %__MODULE__{
          values: [term()]
        }
  defstruct [:values]

  def advance(%__MODULE__{values: []} = cycle) do
    cycle
  end

  def advance(%__MODULE__{values: [_]} = cycle) do
    cycle
  end

  def advance(%__MODULE__{values: [head | rest]} = cycle) do
    %__MODULE__{cycle | values: rest ++ [head]}
  end

  @spec new(values :: [term()]) :: t()
  def new(values) do
    %__MODULE__{values: values}
  end

  @spec next(t(), arguments :: [term()]) :: {:ok, t(), term()} | :error
  def next(%__MODULE__{values: []} = cycle, _arguments) do
    {:ok, cycle, nil}
  end

  def next(%__MODULE__{values: [value]} = cycle, _arguments) do
    {:ok, cycle, value}
  end

  def next(%__MODULE__{values: [head | rest]} = cycle, _arguments) do
    cycle = %__MODULE__{cycle | values: rest ++ [head]}
    {:ok, cycle, head}
  end
end
