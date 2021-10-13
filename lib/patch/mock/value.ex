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

  defguard is_value(module) when module in @value_modules


  def raises(message) do
    callable(fn _ -> raise message end, :list)
  end

  def raises(exception, attributes) do
    callable(fn _ -> raise exception, attributes end, :list)
  end

  def throws(term) do
    callable(fn _ -> throw term end, :list)
  end

  @spec advance(value :: t()) :: t()
  def advance(%module{} = value) when is_value(module) do
    module.advance(value)
  end

  def advance(value) do
    value
  end

  @spec next(value :: t(), arguments :: [term()]) :: {t(), term()}
  def next(%Values.Scalar{} = value, arguments) do
    Values.Scalar.next(value, arguments)
  end

  def next(%module{} = value, arguments) when is_value(module) do
    {next, return_value} = module.next(value, arguments)
    {_, return_value} = next(return_value, arguments)
    {next, return_value}
  end

  def next(callable, arguments) when is_function(callable) do
    {callable, apply(callable, arguments)}
  end

  def next(scalar, _arguments) do
    {scalar, scalar}
  end
end
