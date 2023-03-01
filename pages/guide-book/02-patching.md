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

No matter how many times we call `String.upcase/1` from here on in and no matter what arguments we pass, we will always get back the value `:patched`.

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

### Passthrough vs Strict Evaluation

By default `Patch` will evaluate the callable in `:passthrough` mode.  In passthrough mode if the callable raises either `BadArityError` or `FunctionClauseError` then the original function will be called.  In `:strict` mode these errors will be returned.

One of the core design principles underlying `Patch` is that it tries to obey the intent of the test author.  Consider the following example.

```elixir
defmodule Example do
  use GenServer

  # Snip all the GenServer boilerplate

  def handle_call({:a, argument}, _from, state) do
    # Operation A Definition
    {:reply, result, state}
  end

  def handle_call({:b, argument}, _from, state) do
    # Operation B Definition
    {:reply, result, state}
  end
end
```

When a test author writes the following test code, how should `Patch` interpret it?

```elixir
patch(Example, :handle_call fn
  {:a, _argument}, _from, state ->
    {:reply, :ok, state}
end)
```

There are two possible interpretations, either the test author wants to patch the callback responsible for handling messages shaped like `{:a, argument}` or the test author intends to replace all handle_call callback with one only capable of handling `{:a, argument}`.

`Patch` already has an opinion on which of these to prefer, we can see it in how `Patch` handles patching out one function in a module.  The assumption is that the test author will apply the minimum patch possible, so patching a single function in a module leaves all the other functions in the module as they were.  Applying a similar "default passthrough" behavior to this situation it leads us to one conclusion, the test author probably just wants to replace the functionality handling `{:a, argument}` and should leave the other callbacks alone.

There are always exceptions to the default rule, and `Patch` wants to make it possible to express the other idea.  The test author can inform `Patch` of their intention by using the `:strict` evaluation mode.

```elixir
patch(Example, :handle_call, callable(fn
  {:a, _argument}, _from, state ->
    {:reply, :ok, state}
end, evaluate: :strict))
```

### Stacked Callables

Callables stack as they are defined in the test.  Every time a function is patched with a callable, that callable is pushed to the top of the stack.  When the patched function is called, the stack is walked from the top to bottom to find a callable that can handle it.

There are two problems that are nicely solved by Stacked Callables.  Patching functions with multiple arities and making pattern matching in patching composable.
#### Stacking and Multiple Arities

The first problem that Stacked Callables solves is patching functions with multiple arities.  Consider this example module.

```elixir
defmodule Example do
  def example(a) do
    {:original, a}
  end

  def example(a, b, c) do
    {:original, a, b, c}
  end
end
```

This module defines two functions `example/1` and `example/3`.  How can we patch both functions?  Our first attempt might look something like this:

 **Note: this code is invalid and won't compile**

```elixir
patch(Example, :example, fn
  a ->
    {:patched, a}
    
  a, b, c ->
    {:patched, a, b, c}
end)
```

This code is illegal in Elixir, the compiler will throw a CompileError and explain that you "cannot mix clauses with different arities in anonymous functions."

The first solution for this was introduced in v0.6.0 and took the form of a "dispatch mode." By default `Patch` will use the `:apply` mode, which calls the function with the same arity as the patched function was called.  There is an alternative "dispatch mode" called `:list` which will pass all the arguments as a single argument, a list of the arguments.

**This code will work, but is unwieldy** 

```elixir
patch(Example, :example, callable(fn 
  [a] ->
    {:patched, a}

  [a, b, c] ->
    {:patched, a, b, c}
end, dispatch: :list)
```

This solution made it possible to handle multiple arities, but it is pretty clunky.  With stacked callables we can actually just define two separate callables, one for arity 1, and one for arity 3.

**This code works and is easy to read and write**

```elixir
patch(Example, :example, fn a -> {:patched, a} end)
patch(Example, :example, fn a, b, c -> {:patched, a, b, c} end)
```

To understand how this works, let's look at how a call to `example/1` and a call to `example/3` work.  The first thing we have to understand is what the Callable Stack looks like, so let's diagram it.

```elixir
# Top of Stack (latest defined callable)
[
  fn a, b, c -> {:patched, a, b, c} end,
  fn a -> {:patched, a} end
]
# Bottom of Stack (earliest defined callable)
```

`Patch` will run each function until one returns a valid value, the first function to respond with a return value will cause evaluation to complete.

When `Example.example(1)` is evaluated it will try the first function.  This function has a different arity so it will raise `BadArityError`, this is one of the two errors that engages passthrough behavior.  Since the first entry in the stack resulted in a logical passthrough `Patch` will try the next entry.  The next entry has the right arity and results in `{:patched, 1}` being returned.  

When `Example.example(1, 2, 3)` is evaluated, it's a bit simpler.  The first function is tried and it matches in arity so it immediately returns `{:patched, 1, 2, 3}` and evaluation is completed.

#### Stacking and Matching

Another problem that Stacked Callables helps solve is composability when patching with pattern matching.  Consider the following example module.

```elixir
defmodule Example do
  def handle(:a) do
    {:original, :a}
  end

  def handle(:b) do
    {:original, :b}
  end

  def handle(:c) do
    {:original, :c}
  end
end
```

If a test author wanted to provide patched behavior for `:a` and `:b` they can do so like this.

```elixir
patch(Example, :handle, fn
  :a ->
    {:patched, :a}
    
  :b ->
    {:patched, :b}
end)
```

Which is a very convenient use of built-in Elixir feature, namely that anonymous functions can have multiple clauses.  But what if we want to have a common behavior for patching out the handling of `:a` and the handling of `:b`.  Perhaps in one test we want patch out `:a`, in another `:a` and `:b`, and in a third just `:b`.  Is there any way that we can DRY up this code and make it composable?

Stacked Callables make this quite nice because it makes it possible to patch multiple clauses at different times.  

```elixir
defmodule ExampleTest do
  use ExUnit
  use Patch

  def patch_a do
    patch(Example, :handle, fn :a -> {:patched, a} end)
  end

  def patch_b do
    patch(Example, :handle, fn :b -> {:patched, b} end)
  end

  test "that cares about :a" do
    patch_a()

    assert Example.handle(:a) == {:patched, :a}
  end

  test "that cares about :a and :b" do
    patch_a()
    patch_b()

    assert Example.handle(:a) == {:patched, :a}
    assert Example.handle(:b) == {:patched, :b}
  end

  test "that cares about :b" do
    patch_b()

    assert Example.handle(:b) == {:patched, :b}
  end
end
```

Besides improving composability, it can also just make test code easier to read by breaking multiple logical patches into multiple calls.

Compare

```elixir
patch(Example, :handle, fn
  :a ->
    {:patched, :a}
    
  :b ->
    {:patched, :b}
end)
```

with

```elixir
patch(Example, :handle, fn :a -> {:patched, :a} end) 
patch(Example, :handle, fn :b -> {:patched, :b} end)
```

The power of this mechanism becomes readily apparent when applied to something like GenServer

```elixir
patch(Example, :handle_call, fn {:a, _args}, _from, state -> {:reply, :ok, state} end)
patch(Example, :handle_call, fn {:b, _args}, _from, state -> {:reply, :ok, state} end)
```

It is common for a GenServer to have many handle_call, handle_cast, and handle_info callbacks.  Being able to define the patches by the pattern makes it easy to patch out a subset of the GenServer's behavior

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
## Other Values

There are other types of values supported by `Patch`, see [Chapter 3: Mock Values](03-mock-values.html)

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

After a patch is applied, all subsequent calls to the module become "Observed Calls" and tests can assert that an expected call has occurred by using the `assert_called/1` macro.

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

`assert_called/1` supports full pattern matching and non-hygienic binds.  This is similar to how ExUnit's `assert_receive/3` and `assert_received/2` work.

```elixir
# Wildcards are supported
assert_called String.upcase(_)

# Pinned variables are supported
expected = "hello"
assert_called String.upcase(^expected)

# Unpinned variables are supported
assert_called String.upcase(argument)
assert argument == "hello"
```

Tests can also refute that a call has occurred with the `refute_called/1` macro.  This macro works in much the same way as `assert_called/1` and has full pattern support.

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

### Asserting / Refuting Call Once

We can assert that a call has only happened once with the `assert_called_once/1` macro.  This assertion will only pass if the only one observed call matches.

```elixir
defmodule PatchExample do
  use ExUnit.Case
  use Patch

  test "refuting a patch was called once" do
    patch(String, :upcase, :patched)

    assert_called_once String.upcase("hello")   # Assertion fails before the function is called.

    assert :patched == String.upcase("hello")

    assert_called_once String.upcase("hello")   # Assertion passes after called once.

    assert :patched == String.upcase("hello")

    assert_called_once String.upcase("hello")   # Assertion fails after second call.
  end
end
```

`assert_called_once/1` supports patterns and binds just like `assert_called/1`.  In the above example the following assertion would behave identically.

```elixir
# Wildcards are supported
assert_called_once String.upcase(_)

# Pinned variables are supported
expected = "hello"
assert_called_once String.upcase(^expected)

# Unpinned variables are supported
assert_called_once String.upcase(argument)
assert argument == "hello"
```

Tests can also refute that a call has occurred once with the `refute_called_once/1` macro.  This macro works in much the same way as `assert_called_once/1` and has full pattern support.

```elixir
defmodule PatchExample do
  use ExUnit.Case
  use Patch

  test "refuting calls on a patch" do
    patch(String, :upcase, :patched)

    refute_called_once String.upcase("hello")   # Assertion passes before the function is called.

    assert :patched == String.upcase("hello")

    refute_called_once String.upcase("hello")   # Assertion fails after called once.

    assert :patched == String.upcase("hello")

    refute_called_once String.upcase("hello")   # Assertion passes after second call.
  end
end
```

### Asserting / Refuting Call Counts

We can assert that a call has happened some given number of times exactly with the `assert_called/2` macro.  The second argument is the number of observed call matches there must be to pass.

```elixir
defmodule PatchExample do
  use ExUnit.Case
  use Patch

  test "asserting 3 calls on a patch" do
    patch(String, :upcase, :patched)

    assert :patched == String.upcase("hello")

    assert_called String.upcase("hello"), 3   # Assertion fails after first call.
    
    assert :patched == String.upcase("hello")

    assert_called String.upcase("hello"), 3   # Assertion fails after second call.
    
    assert :patched == String.upcase("hello")

    assert_called String.upcase("hello"), 3   # Assertion passes after third call.
  end
end
```

`assert_called/2` supports patterns and binds just like `assert_called/1`.  Since multiple calls might match any binds bind to the latest matching call.

In the above example the following assertion would behave identically.

```elixir
# Wildcards are supported
assert_called String.upcase(_), 3

# Pinned variables are supported
expected = "hello"
assert_called String.upcase(^expected), 3

# Unpinned variables are supported
assert_called String.upcase(argument), 3
assert argument == "hello"
```

Tests can also refute that a call has happened an exact number of times with the `refute_called/2` macro.  This macro works in much the same way as `assert_called/2` and also has full pattern support.

```elixir
defmodule PatchExample do
  use ExUnit.Case
  use Patch

  test "refuting 3 calls on a patch" do
    patch(String, :upcase, :patched)

    assert :patched == String.upcase("hello")

    refute_called String.upcase("hello"), 3   # Assertion passes after first call.
    
    assert :patched == String.upcase("hello")

    refute_called String.upcase("hello"), 3   # Assertion passes after second call.
    
    assert :patched == String.upcase("hello")

    refute_called String.upcase("hello"), 3   # Assertion fails after third call.
  end
end
```

### Asserting / Refuting Multiple Arities

If a function has multiple arities that may be called based on different conditions the test author may wish to assert or refute that a function has been called at all without regards to the number of arguments passed.

This can be accomplished with the `assert_any_call/1` and `refute_any_call/1` functions.


```elixir
defmodule PatchExample do
  use ExUnit.Case
  use Patch

  test "asserting any call on a patch" do
    patch(String, :pad_leading, fn s -> s end)

    # This formatting call might provide custom padding characters based on
    # time of day.  (This is an obviously constructed example).
    TimeOfDaySensitiveFormatter.format("Hello World")

    assert_any_call String.pad_leading
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

    refute_any_call String.pad_leading
  end
end
```

#### Advanced Use Cases

The `assert_any_call/2` and `refute_any_call/2` functions take two arguments the module and the function name as an 
atom.  This allows some more advanced use cases where the module or function isn't known at test authoring time.

```elixir
defmodule PatchExample
  use ExUnit.Case
  use Patch

  test "asserting any call on normalizer" do
    spy(Formatter)

    normalizer = Formatter.get_normalizer()

    assert_any_call Fromatter, normalizer   # Assertion fails before call

    Formatter.normalize("hello", with: normalizer)

    assert_any_call Fromatter, normalizer   # Assertion passes after call
  end
end
```

Similarly we can refute any call

```elixir
defmodule PatchExample
  use ExUnit.Case
  use Patch

  test "refuting any call on normalizer" do
    spy(Formatter)

    normalizer = Formatter.get_normalizer()

    refute_any_call Formatter, normalizer   # Assertion passes before call

    Formatter.normalize("hello", with: normalizer)

    refute_any_call Formatter, normalizer   # Assertion fails after call
  end
end
```

    