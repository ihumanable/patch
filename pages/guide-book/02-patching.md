# Chapter 2: Patching

The most common operation a test author will perform with `Patch` is, unsurprisingly, patching things.

When a module is patched, the patched function will return the mock value provided.

## Scalar Values

The simplest kind of patch is one that just returns a static scalar value on every invocation.

```elixir
defmodule PatchExample do
  use ExUnit.Case
  use Patch

  test "functions can be patched to return a specified value" do
    # Assertion passes before patching
    assert "HELLO" == String.upcase("hello")

    # The function can be patched to return a static scalar value
    patch(String, :upcase, :patched)

    # Assertion passes after patching
    assert :patched == String.upcase("hello")  
  end
end
```

No many how many times we call `String.upcase/1` from here on in and no matter what arguments we pass, we will always get back the value `:patched`.

## Callable Values

Modules can also be patched to run custom logic instead of returning a static value

```elixir
defmodule PatchExample do
  use ExUnit.Case
  use Patch

  test "functions can be patched with a replacement function" do
    # Assertion passes before patching
    assert "HELLO" == String.upcase("hello")

    # The function can be patched to run custom code
    patch(String, :upcase, fn s -> String.length(s) end)

    # Assertion passes after patching
    assert 5 == String.upcase("hello")
  end
end
```

Every time we call `String.upcase/1` it will run our function and return the length of the input.  

## Other Values

There are other types of values supported by `Patch`, see [Chapter 3: Mock Values](03-mock-values.html)

### Callables with Multiple Arities

`String.upcase` actually comes in 2 arities, `String.upcase/1` and `String.upcase/2`.  In the above we only define a callable that handles arity 1 calls.  A first attempt might be to provide multiple clauses in our anonymous function.  

**This code doesn't work**

```elixir
    # The function can be patched to run custom code
    patch(String, :upcase, fn 
      s -> 
        String.length(s) 

      s, _ ->
        String.length(s)
    end)
```

This code is illegal in Elixir, the compiler will throw a CompileError and explain that you "cannot mix clauses with different arities in anonymous functions."

This is where the callable "dispatch mode" kicks in.  By default `Patch` will use the `:apply` mode, which calls the function with the same arity as the patched function was called.  There is an alternative "dispatch mode" called `:list` which will pass all the arguments as a single argument, a list of the arguments.

**This code will work**

```elixir
    # The function can be patched to run custom code
    patch(String, :upcase, callable(fn 
      [s | _] -> 
        String.length(s) 
    end, :list)
```

So now we have a function that gets a list of arguments.  It only ever cares about the first argument so it pattern matches that value out.  The second argument to `callable/2` defines the "dispatch mode."

### Functions as Scalars

If functions are always considered callable, how can we patch a function so that it returns a function literal?  This can be accomplished by wrapping the function in a call to `scalar/1` to turn it into a scalar.

```elixir
defmodule PatchExample do
  use ExUnit.Case
  use Patch

  test "patch returns a function literal" do
    patch(Example, :get_name_normalizer, scalar(&String.downcase/1))

    normalizer = Example.get_name_normalizer()
    assert normalizer.("Patch") == "patch"
  end
end
```

## Ergonomics

`patch/3` returns the value that the patch will return which can be useful for later on in the test.  Examine this example code for an example

```elixir
defmodule PatchExample do
  use ExUnit.Case
  use Patch

  test "patch returns the patch" do
    {:ok, expected} = patch(My.Module, :some_function, {:ok, 123})

    # ... additional testing code ...

    assert response.some_function_result == expected
  end
end
```

This allows the test author to combine creating fixture data with patching.

## Asserting / Refuting Calls

After a patch is applied, all subsequent calls to the module become "Observered Calls" and tests can assert that an expected call has occurred by using the `assert_called` macro.

```elixir
defmodule PatchExample do
  use ExUnit.Case
  use Patch

  test "asserting calls on a patch" do
    patch(String, :upcase, :patched)

    assert :patched = String.upcase("hello")   # Assertion passes after patching

    assert_called String.upcase("hello")       # Assertion passes after call
  end
end
```

`assert_called` supports the `:_` wildcard atom.  In the above example the following assertion would also pass.

```elixir
assert_called String.upcase(:_)
```

This can be useful when some of the arguments are complex or uninteresting for the unit test.

Tests can also refute that a call has occurred with the `refute_called` macro.  This macro works in much the same way as `assert_called` and also supports the `:_` wildcard atom.

```elixir
defmodule PatchExample do
  use ExUnit.Case
  use Patch

  test "refuting calls on a patch" do
    patch(String, :upcase, :patched)

    assert "h" == String.at("hello", 0)

    refute_called String.upcase("hello")
  end
end
```

### Asserting / Refuting Multiple Arities

If a function has multiple arities that may be called based on different conditions the test author may wish to assert or refute that a function has been called at all without regards to the number of arguments passed.

This can be accomplished with the `assert_any_call/2` and `refute_any_call/2` functions.

These functions take two arguments the module and the function name as an atom.

```elixir
defmodule PatchExample do
  use ExUnit.Case
  use Patch

  test "asserting any call on a patch" do
    patch(String, :pad_leading, fn s -> s end)

    # This formatting call might provide custom padding characters based on
    # time of day.  (This is an obviously constructed example).
    TimeOfDaySensitiveFormatter.format("Hello World")

    assert_any_call String, :pad_leading
  end
end
```

Similarly we can refute any call

```elixir
defmodule PatchExample do
  use ExUnit.Case
  use Patch

  test "refuting any call on a patch" do
    patch(String, :pad_leading, fn s -> s end)

    assert {:error, :not_a_string} = TimeOfDaySensitiveFormatter.format(123)

    refute_any_call String, :pad_leading
  end
end
```