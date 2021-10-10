defmodule Patch.Mock.Values.Callable do
  @type dispatch_mode :: :apply | :list

  @type t :: %__MODULE__{
          dispatch: dispatch_mode(),
          target: function()
        }
  defstruct [:dispatch, :target]

  @spec new(target :: function(), dispatch :: dispatch_mode()) :: t()
  def new(target, dispatch \\ :apply) do
    %__MODULE__{dispatch: dispatch, target: target}
  end

  @spec next(callable :: t(), arguments :: [term()]) :: {:ok, t(), term()} | :error
  def next(%__MODULE__{dispatch: :apply} = callable, arguments) do
    with {:ok, result} <- do_apply(callable.target, arguments) do
      {:ok, callable, result}
    end
  end

  def next(%__MODULE__{dispatch: :list} = callable, arguments) do
    with {:ok, result} <- do_apply(callable.target, [arguments]) do
      {:ok, callable, result}
    end
  end

  ## Private

  @spec do_apply(target :: function(), arguments :: [term()]) :: {:ok, term()} | :error
  defp do_apply(target, arguments) do
    try do
      result = apply(target, arguments)
      {:ok, result}
    catch
      _, _ ->
        :error
    end
  end
end
