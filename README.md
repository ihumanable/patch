# Patch

Patch - Ergonomic Mocking for Elixir

Patch makes it easy to mock one or more functions in a module returning a value or executing
custom logic.  Patches and Spies allow tests to assert or refute that function calls have been
made.

## Installation

Add patch to your mix.exs

```elixir
def deps do
  [
    {:patch, "~> 0.1", only: [:test]}
  ]
end
```

## Quickstart

After adding the dependency just add the following line to any test module after using your test case

```elixir
use Patch
```

## Patches

When a module is patched, the patched function will return the value provided.

```elixir
assert "HELLO" = String.upcase("hello")                 # Assertion passes before patching

patch(String, :upcase, :patched_return_value)

assert :patched_return_value == String.upcase("hello")  # Assertion passes after patching
```

Modules can also be patched to run custom logic instead of returning a static value

```elixir
assert "HELLO" = String.upcase("hello")                 # Assertion passes before patching

patch(String, :upcase, fn s -> String.length(s) end)

assert 5 == String.upcase("hello")                      # Assertion passes after patching
```

### Patching Ergonomics

`patch/3` returns the value that the patch will return which can be useful for later on in the
test.  Examine this example code for an example

```elixir
{:ok, expected} = patch(My.Module, :some_function, {:ok, 123})

... additional testing code ...

assert response.some_function_result == expected
```

This allows the test author to combine creating fixture data with patching.

## Asserting / Refuting Calls

After a patch is applied, tests can assert that an expected call has occurred by using the
`assert_called` macro.

```elixir
patch(String, :upcase, :patched_return_value)

assert :patched_return_value = String.upcase("hello")   # Assertion passes after patching

assert_called String.upcase("hello")                    # Assertion passes after call
```

`assert_called` supports the `:_` wildcard atom.  In the above example the following assertion
would also pass.

```elixir
assert_called String.upcase(:_)
```

This can be useful when some of the arguments are complex or uninteresting for the unit test.

Tests can also refute that a call has occurred with the `refute_called` macro.  This macro works
in much the same way as `assert_called` and also supports the `:_` wildcard atom.

## Spies

If a test wishes to assert / refute calls that happen to a module without actually changing the
behavior of the module it can simply `spy/1` the module.  Spies behave identically to the
original module but all calls and return values are recorded so assert_called and refute_called
work as expected.

## Limitations

Patch currently can only mock out functions of arity /0 - /10.  If a function with greater arity
needs to be patched this module will need to be updated.