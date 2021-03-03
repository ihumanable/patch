# Patch

[![CI](https://github.com/ihumanable/patch/workflows/CI/badge.svg)](https://github.com/ihumanable/patch/actions)
[![Hex.pm Version](http://img.shields.io/hexpm/v/patch.svg?style=flat)](https://hex.pm/packages/patch)
[![Hex.pm License](http://img.shields.io/hexpm/l/patch.svg?style=flat)](https://hex.pm/packages/patch)
[![HexDocs](https://img.shields.io/badge/HexDocs-Yes-blue)](https://hexdocs.pm/patch)

Patch - Ergonomic Mocking for Elixir

Patch makes it easy to mock one or more functions in a module returning a value or executing
custom logic.  Patches and Spies allow tests to assert or refute that function calls have been
made.

## Installation

Add patch to your mix.exs

```elixir
def deps do
  [
    {:patch, "~> 0.2.0", only: [:test]}
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

### Multiple Arities

If a function has multiple arities that may be called based on different conditions the test
author may wish to assert or refute that a function has been called at all without regards to the
number of arguments passed.

This can be accomplished with the `assert_any_call/2` and `refute_any_call/2` functions.

These functions take two arguments the module and the function name as an atom.
## Spies

If a test wishes to assert / refute calls that happen to a module without actually changing the
behavior of the module it can simply `spy/1` the module.  Spies behave identically to the
original module but all calls and return values are recorded so `assert_called` and `refute_called`
work as expected.
