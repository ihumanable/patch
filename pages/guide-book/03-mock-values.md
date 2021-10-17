# Chapter 3: Mock Values

In [Chapter 2: Patching](02-patching.html) we covered two kinds of mock values, Callables and Scalars.

There are 5 other kinds of mock values available for use in a test.

## Cycle Values

Cycle Values will endlessly cycle through a list of return values.  

When a patched function has a `Values.Cycle` as its mock value, it will provide the first value in the cycle and then move the first value to the end of the cycle on every invocation.

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

We could continue the above table forever since the cycle will repeat endlessly.  Cycles can contain `callable/1,2`, `raise/1,2` and `throw/1` mock values.

We could create a patch that raises a RuntimeError every other call.

```elixir
patch(Example, :example, cycle([:ok, raises("broken")]))
```

This can be helpful for testing retry and backoff constructs, a cycle like this is a good simulation of an unreliable network or dependency.

## Sequence Values

Sequence values are similar to cycles, but instead of cycling the list is consumed until only one element is remaining.  Once the sequence has only a single element remaining, that element will be returned on all subsequent calls.

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

We could continue the above table forever since the sequence will continue to return the last value endlessly.  Sequences can contain `callable/1,2`, `raise/1,2` and `throw/1` mock values.

There is one special behavior of sequence, and that's an empty sequence, which always returns the value `nil` on every invocation.

If the test author would like to simulate an exhaustable sequence, one that returns a set number of items and then responds to every other call with `nil`, they can simply add a `nil` as the last element in the sequence

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

## Raises Value

When a function can fail by raising an exception we can use `raises/1,2` to have the patched function raise.

`raise/1` creates a special `Values.Callable` to be used as a mock value.

This callable ignores the arguments passed in and unconditionally raises a `RuntimeError` with the
given message.

```elixir
patch(Example, :example, raises("patched"))

assert_raise RuntimeError, "patched", fn ->
  Example.example()
end
```

`raise/2` creates a special `Values.Callable` to be used as a mock value.

This callable ignores the arguments passed in and unconditionally raises the specified exception with the given attributes.

```elixir
patch(Example, :example, raises(ArgumentError, message: "patched"))

assert_raise ArgumentError, "patched", fn ->
  Example.example()
end
```

## Throws Value

When a function can fail by raising an exception we can use `throws/1` to have the patched function throw.

`throws/1` creates a special `Values.Callable` to be used as a mock value.

This callable ignores the arguments passed in and unconditionally throws the given value.

```elixir
patch(Example, :example, throws(:patched))

assert catch_throw(Example.example()) == :patched
```

