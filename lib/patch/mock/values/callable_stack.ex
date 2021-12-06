defmodule Patch.Mock.Values.CallableStack do
  alias Patch.Mock.Values.Callable

  @type t :: %__MODULE__{
    stack: [Callable.t()]
  }
  defstruct [:stack]

  @spec advance(stack :: t()) :: t()
  def advance(stack) do
    stack
  end

  @spec new(stack :: [Callable.t()]) :: t()
  def new(stack) do
    %__MODULE__{stack: stack}
  end

  @spec next(stack :: t(), arguments :: [term()]) :: {:ok, t(), term()} | :error
  def next(%__MODULE__{} = stack, arguments) do
    Enum.reduce_while(stack.stack, :error, fn callable, acc ->
      case Callable.next(callable, arguments) do
        {:ok, _callable, result} ->
          {:halt, {:ok, stack, result}}

        :error ->
          {:cont, acc}
      end
    end)
  end

  @spec push(stack :: t(), callable :: Callable.t()) :: t()
  def push(%__MODULE__{} = stack, %Callable{} = callable) do
    %__MODULE__{stack | stack: [callable | stack.stack]}
  end
end
