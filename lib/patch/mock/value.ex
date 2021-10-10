defmodule Patch.Mock.Value do
  alias Patch.Mock.Values

  @type t ::
          Values.Callable.t()
          | Values.Cycle.t()
          | Values.Scalar.t()
          | Values.Sequence.t()
          | term()

  @value_modules [Values.Callable, Values.Cycle, Values.Scalar, Values.Sequence]

  defdelegate callable(target, dispatch \\ :apply), to: Values.Callable, as: :new
  defdelegate cycle(enumerable), to: Values.Cycle, as: :new
  defdelegate scalar(value), to: Values.Scalar, as: :new
  defdelegate sequence(enumerable), to: Values.Sequence, as: :new

  @spec next(value :: t(), arguments :: [term()]) :: {:ok, t(), term()} | :error
  def next(%module{} = value, arguments) when module in @value_modules do
    with {:ok, next_value, return_value} <- module.next(value, arguments) do
      case next(return_value, arguments) do
        {:ok, _, return_value} ->
          {:ok, next_value, return_value}

        :error ->
          {:ok, next_value, return_value}
      end
    end
  end

  def next(scalar, _arguments) do
    {:ok, scalar, scalar}
  end
end
