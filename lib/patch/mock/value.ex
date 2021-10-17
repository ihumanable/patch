defmodule Patch.Mock.Value do
  @moduledoc """
  Interface for generating mock values.

  In a test this module is imported into the test and so using this module directly is not
  necessary.
  """

  alias Patch.Mock.Values

  @type t ::
          Values.Callable.t()
          | Values.Cycle.t()
          | Values.Scalar.t()
          | Values.Sequence.t()
          | term()

  @value_modules [Values.Callable, Values.Cycle, Values.Scalar, Values.Sequence]

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

  ```
  patch(Example, :example, fn arg -> {:patched, arg} end)

  assert Example.example(1) == {:patched, 1}   # passes
  assert Example.example(2) == {:patched, 2}   # passes
  assert Example.example(3) == {:patched, 3}   # passes
  ```

  `callable/2` allows the test author to provide a `dispatch_mode` of either `:apply` or `:list`.

  When `:apply` is used the function is called with the same arity of the patched function.  When
  `:list` is used the function is always called with a single argument, a list of arguments to the
  patched function.

  ```elixir
  patch(Example, :example, callable(fn a, b, c -> {:patched, a, b, c} end), :apply)

  assert Example.example(1, 2, 3)  == {:patched, 1, 2, 3}   # passes

  assert_raise BadArityError, fn ->
    Example.example(:test)
  end
  ```

  Compare this with using list dispatch

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

  When multiple arity support is needed, use `:list` dispatch.
  """
  @spec callable(target :: function(), dispatch :: Values.Callable.dispatch_mode()) :: Values.Callable.t()
  defdelegate callable(target, dispatch \\ :apply), to: Values.Callable, as: :new

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
  Creates a special `Values.Callable` to be used as a mock value.

  This callable ignores the arguments passed in and unconditionally raises a RuntimeError with the
  given message.

  ```elixir
  patch(Example, :example, raises("patched"))

  assert_raise RuntimeError, "patched", fn ->
    Example.example()
  end
  ```
  """
  @spec raises(message :: String.t()) :: Values.Callable.t()
  def raises(message) do
    callable(fn _ -> raise message end, :list)
  end

  @doc """
  Creates a special `Values.Callable` to be used as a mock value.

  This callable ignores the arguments passed in and unconditionally raises the specified exception
  with the given attributes.

  ```elixir
  patch(Example, :example, raises(ArgumentError, message: "patched"))

  assert_raise ArgumentError, "patched", fn ->
    Example.example()
  end
  ```
  """
  @spec raises(exception :: module(), attributes :: Keyword.t()) :: Values.Callable.t()
  def raises(exception, attributes) do
    callable(fn _ -> raise exception, attributes end, :list)
  end

  @doc """
  Creates a special `Values.Callable` to be used as a mock value.

  This callable ignores the arguments passed in and unconditionally throws the given value.

  ```elixir
  patch(Example, :example, throws(:patched))

  assert catch_throw(Example.example()) == :patched
  ```
  """
  @spec throws(value :: term()) :: Values.Callable.t()
  def throws(value) do
    callable(fn _ -> throw value end, :list)
  end

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
