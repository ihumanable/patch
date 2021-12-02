defmodule Patch.Mock.Values.Callable do
  alias Patch.Apply

  @type dispatch_mode :: :apply | :list

  @type t :: %__MODULE__{
          dispatch: dispatch_mode(),
          target: function()
        }
  defstruct [:dispatch, :target]

  @spec advance(callable :: t()) :: t()
  def advance(callable) do
    callable
  end

  @spec new(target :: function(), dispatch :: dispatch_mode()) :: t()
  def new(target, dispatch \\ :apply) do
    %__MODULE__{dispatch: dispatch, target: target}
  end

  @spec next(callable :: t(), arguments :: [term()]) :: {:ok, t(), term()} | :error
  def next(%__MODULE__{dispatch: :apply} = callable, arguments) do
    with {:ok, result} <- Apply.safe(callable.target, arguments) do
      {:ok, callable, result}
    end
  end

  def next(%__MODULE__{dispatch: :list} = callable, arguments) do
    with {:ok, result} <- Apply.safe(callable.target, [arguments]) do
      {:ok, callable, result}
    end
  end
end
