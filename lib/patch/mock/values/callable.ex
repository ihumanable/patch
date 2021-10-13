defmodule Patch.Mock.Values.Callable do
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

  @spec next(callable :: t(), arguments :: [term()]) :: {t(), term()}
  def next(%__MODULE__{dispatch: :apply} = callable, arguments) do
    {callable, apply(callable.target, arguments)}
  end

  def next(%__MODULE__{dispatch: :list} = callable, arguments) do
    {callable, apply(callable.target, [arguments])}
  end
end
