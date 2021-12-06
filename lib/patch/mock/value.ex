defmodule Patch.Mock.Value do
  @moduledoc """
  Interface for generating mock values.

  In a test this module is imported into the test and so using this module directly is not
  necessary.
  """

  alias Patch.Apply
  alias Patch.Mock.Values

  @type t ::
          Values.Callable.t()
          | Values.CallableStack.t()
          | Values.Cycle.t()
          | Values.Raises.t()
          | Values.Scalar.t()
          | Values.Sequence.t()
          | Values.Throws.t()
          | term()

  @value_modules [
    Values.Callable,
    Values.CallableStack,
    Values.Cycle,
    Values.Raises,
    Values.Scalar,
    Values.Sequence,
    Values.Throws
  ]

  @doc """
  Create a new `Values.Callable` to be used as the mock value.

  When a patched function has a `Values.Callable` as its mock value, it will invoke the callable
  with the arguments to the patched function on every invocation to generate a new value to
  return.

  ```elixir
  patch(Example, :example, callable(fn arg -> {:patched, arg} end))

  assert Example.example(1) == {:patched, 1}   # passes
  assert Example.example(2) == {:patched, 2}   # passes
  assert Example.example(3) == {:patched, 3}   # passes
  ```

  Any function literal will automatically be promoted into a `Values.Callable` unless it is
  wrapped in a `scalar/1` call.

  See `callable/2` for more configuration options.  `callable/1` calls use the default
  configuration options

  - dispatch: :apply
  - evaluate: :passthrough
  """
  @spec callable(target :: function()) :: Values.Callable.t()
  def callable(target) do
    callable(target, [])
  end

  @doc """
  `callable/2` allows the test author to provide additional configuration.

  There are two options

  ## `:dispatch`

  Controls how the arguments are dispatched to the callable.

  - `:apply` is the default.  It will call the function with the same arity as the incoming call.
  - `:list` will always call the callable with a single argument, a list of all the incoming
    arguments.

  ### Apply Example

  ```elixir
  patch(Example, :example, callable(fn a, b, c -> {:patched, a, b, c} end), :apply)

  assert Example.example(1, 2, 3)  == {:patched, 1, 2, 3}   # passes
  ```

  ### List Example

  ```elixir
  patch(Example, :example, callable(fn
    [a, b, c] ->
      {:patched, a, b, c}

    [a] ->
      {:patched, a}
  end, :list))

  assert Example.example(1, 2, 3) == {:patched, 1, 2, 3}   # passes
  assert Example.example(1) == {:patched, 1}   # passes
  ```

  ## `:evaluate`

  Controls how the callable is evaluated.

  - `:passthrough` is the default.  It will passthrough to the original function if the provided
    callable fails to pattern match to the incoming call
  - `:strict` will bubble up any `BadArityError` or `FunctionClauseErrors`.

  ## Legacy Configuration Behavior (may be deprecated)

  This function accepts either a single atom, in which case it will assign that to the `:dispatch`
  configuration and use the default `:evaluate` option.

  The following calls are equivalent

  ```elixir
  # Using legacy configuration convention
  patch(Example, :example, callable(fn args -> {:patched, args}, :apply))

  # Using explicit options without evaluate
  patch(Example, :example, callable(fn args -> {:patched, args}, dispatch: :apply))

  # Using fully specified explicit options
  patch(Example, :example, callable(fn args -> {:patched, args}, dispatch: :apply, evaluate: :passthrough))
  ```

  ## Multiple Arities

  `dispatch: :list` used to be the preferred way to deal with multiple arities, here's an example.

  ```elixir
  patch(Example, :example, callable(fn
    [a] ->
      {:patched, a}

    [a, b, c] ->
      {:patched, a, b, c}
  end, dispatch: :list))

  assert Example.example(1) == {:patched, 1}
  assert Example.example(1, 2, 3) == {:patched, 1, 2, 3}
  ```

  Patch now has "Stacked Callables" so the preferred method is to use the equivalent code

  ```elixir
  patch(Example, :example, fn a -> {:patched, a} end)
  patch(Example, :example, fn a, b, c -> {:patched, a, b, c} end)

  assert Example.example(1) == {:patched, 1}
  assert Example.example(1, 2, 3) == {:patched, 1, 2, 3}
  ```
  """

  @spec callable(target :: function(), dispatch :: Values.Callable.dispatch_mode()) :: Values.Callable.t()
  def callable(target, dispatch) when is_atom(dispatch) do
    callable(target, dispatch: dispatch)
  end

  @spec callable(target :: function(), options :: [Values.Callable.option()]) :: Values.Callable.t()
  def callable(target, options) when is_list(options) do
    Values.Callable.new(target, options)
  end

  @doc """
  Create a new `Values.Cycle` to be used as the mock value.

  When a patched function has a `Values.Cycle` as its mock value, it will provide the first value
  in the cycle and then move the first value to the end of the cycle on every invocation.

  Consider a function patched with `cycle([1, 2, 3])` via the following code

  ```elixir
  patch(Example, :example, cycle([1, 2, 3]))
  ```

  | Invocation | Cycle Before Call | Return Value | Cycle After Call |
  |------------|-------------------|--------------|------------------|
  | 1          | [1, 2, 3]         | 1            | [2, 3, 1]        |
  | 2          | [2, 3, 1]         | 2            | [3, 1, 2]        |
  | 3          | [3, 1, 2]         | 3            | [1, 2, 3]        |
  | 4          | [1, 2, 3]         | 1            | [2, 3, 1]        |
  | 5          | [2, 3, 1]         | 2            | [3, 1, 2]        |
  | 6          | [3, 1, 2]         | 3            | [1, 2, 3]        |
  | 7          | [1, 2, 3]         | 1            | [2, 3, 1]        |

  We could continue the above table forever since the cycle will repeat endlessly.  Cycles can
  contain `callable/1,2`, `raise/1,2` and `throw/1` mock values.
  """
  @spec cycle(values :: [term()]) :: Values.Cycle.t()
  defdelegate cycle(values), to: Values.Cycle, as: :new

  @doc """
  Creates a new `Values.Scalar` to be used as the mock value.

  When a patched function has a `Values.Scalar` as its mock value, it will provide the scalar
  value on every invocation

  ```elixir
  patch(Example, :example, scalar(:patched))

  assert Example.example() == :patched   # passes
  assert Example.example() == :patched   # passes
  assert Example.example() == :patched   # passes
  ```

  When patching with any term that isn't a function, it will automatically be promoted into a
  `Values.Scalar`.

  ```elixir
  patch(Example, :example, :patched)

  assert Example.example() == :patched   # passes
  assert Example.example() == :patched   # passes
  assert Example.example() == :patched   # passes
  ```

  Since functions are always automatically promoted to `Values.Callable`, if a function is meant
  as a scalar value it **must** be wrapped in a call to `scalar/1`.

  ```elixir
  patch(Example, :get_name_normalizer, scalar(&String.downcase/1))

  assert Example.get_name_normalizer == &String.downcase/1   # passes
  ```
  """
  @spec scalar(value :: term()) :: Values.Scalar.t()
  defdelegate scalar(value), to: Values.Scalar, as: :new

  @doc """
  Creates a new `Values.Sequence` to be used as a mock value.

  When a patched function has a `Values.Sequence` as its mock value, it will provide the first
  value in the sequence as the return value and then discard the first value.  Once the sequence
  is down to a final value it will be retained and returned on every subsequent invocation.

  Consider a function patched with `sequence([1, 2, 3])` via the following code

  ```elixir
  patch(Example, :example, sequence([1, 2, 3]))
  ```

  | Invocation | Sequence Before Call | Return Value | Sequence After Call |
  |------------|----------------------|--------------|---------------------|
  | 1          | [1, 2, 3]            | 1            | [2, 3]              |
  | 2          | [2, 3]               | 2            | [3]                 |
  | 3          | [3]                  | 3            | [3]                 |
  | 4          | [3]                  | 3            | [3]                 |
  | 5          | [3]                  | 3            | [3]                 |

  We could continue the above table forever since the sequence will continue to return the last
  value endlessly.  Sequences can contain `callable/1,2`, `raise/1,2` and `throw/1` mock values.

  There is one special behavior of sequence, and that's an empty sequence, which always returns
  the value `nil` on every invocation.

  If the test author would like to simulate an exhaustable sequence, one that returns a set number
  of items and then responds to every other call with `nil`, they can simply add a `nil` as the
  last element in the sequence

  ```elixir
  patch(Example, :example, sequence([1, 2, 3, nil])
  ```

  | Invocation | Sequence Before Call | Return Value | Sequence After Call |
  |------------|----------------------|--------------|---------------------|
  | 1          | [1, 2, 3, nil]       | 1            | [2, 3, nil]         |
  | 2          | [2, 3, nil]          | 2            | [3, nil]            |
  | 3          | [3, nil]             | 3            | [nil]               |
  | 4          | [nil]                | nil          | [nil]               |
  | 5          | [nil]                | nil          | [nil]               |
  """
  @spec sequence(values :: [term()]) :: Values.Sequence.t()
  defdelegate sequence(values), to: Values.Sequence, as: :new

  @doc """
  Guard that checks whether a value is a proper Values module
  """
  defguard is_value(module) when module in @value_modules

  @doc """
  Creates a special value that raises a RuntimeError with the given message.

  ```elixir
  patch(Example, :example, raises("patched"))

  assert_raise RuntimeError, "patched", fn ->
    Example.example()
  end
  ```
  """
  @spec raises(message :: String.t()) :: Values.Raises.t()
  defdelegate raises(message), to: Values.Raises, as: :new

  @doc """
  Creates a special value that raises the given exception with the provided attributes.

  ```elixir
  patch(Example, :example, raises(ArgumentError, message: "patched"))

  assert_raise ArgumentError, "patched", fn ->
    Example.example()
  end
  ```
  """
  @spec raises(exception :: module(), attributes :: Keyword.t()) :: Values.Raises.t()
  defdelegate raises(exception, attributes), to: Values.Raises, as: :new

  @doc """
  Creates a special values that throws the provided value when evaluated.

  ```elixir
  patch(Example, :example, throws(:patched))

  assert catch_throw(Example.example()) == :patched
  ```
  """
  @spec throws(value :: term()) :: Values.Throws.t()
  defdelegate throws(value), to: Values.Throws, as: :new

  @doc """
  Advances the given value.

  Sequences and Cycles both have meaningful advances, all other values types this acts as a no-op.
  """
  @spec advance(value :: t()) :: t()
  def advance(%module{} = value) when is_value(module) do
    module.advance(value)
  end

  def advance(value) do
    value
  end

  @doc """
  Generate the next return value and advance the underlying value.
  """
  @spec next(value :: t(), arguments :: [term()]) :: {:ok, t(), term()} | :error
  def next(%Values.Scalar{} = value, arguments) do
    Values.Scalar.next(value, arguments)
  end

  def next(%module{} = value, arguments) when is_value(module) do
    with {:ok, next, return_value} <- module.next(value, arguments) do
      {:ok, _, return_value} = next(return_value, arguments)
      {:ok, next, return_value}
    end
  end

  def next(callable, arguments) when is_function(callable) do
    with {:ok, result} <- Apply.safe(callable, arguments) do
      {:ok, callable, result}
    end
  end

  def next(scalar, _arguments) do
    {:ok, scalar, scalar}
  end
end
