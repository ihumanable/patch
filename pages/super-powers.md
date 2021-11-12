# Super Powers

Patch provides unique features that no other mocking library for Elixir offers.  See the [Mockompare](https://github.com/ihumanable/mockompare) suite for a comparison of Elixir / Erlang mocking libraries.  If there is a way to accomplish the following with another library, please open an issue so this section and the comparisons can be updated.

So what are these super powers?

1. Patch mocks are effective for both local and remote calls.  This means a patched function **always** resolves to the patch.
2. Patch can patch private functions without changing their visibility.
3. Patch makes it possible to test your private functions without changing their visibility via the `expose/2` functionality.  

## Local and Remote Calls

In Elixir we have two different ways to call a function, local call vs remote call.

In a local call, the module is not specified.

```elixir
defmodule Example do
  def example do
    collaborator()   # No Module, this is a local call
  end

  def collaborator do
    :original
  end
end
```

In a remote call the module is specified, this is most common when calling from one module to another, but can be done within a module if desired.

```elixir
defmodule Example do
  def example do
    __MODULE__.collaborator()   # Module specified, this is a remote call
  end

  def collaborator do
    :original
  end
end
```

It is exceedingly common to use local calls when writing a module.  The problem comes when mocking a collaborator function.  First, why might we want to mock out a collaborator?  Here's an example where we might want to skip some functionality.

```elixir
defmodule Example do
  def save(thing) do
    if valid?(thing) do
      do_save(thing)
    else
      {:error, :invalid}
    end
  end

  def valid?(thing) do
    [
      &Example.Validation.name_not_blank?/1,
      &Example.Validation.token_hash_valid?/1,
      &Example.Validation.flux_capacitor_within_limits?/1
    ]
    |> Enum.all?(fn validator -> validator.(thing) end)
  end

  defp do_save(thing) do
    DB.insert(thing)
  end
end
```

In the unit tests for `Example.save/1` we want to test the high level logic of "valid gets saved, invalid gets an error."

This is complicated though because `Example.valid?/1` has real validations baked in.  A common approach is to create a fixture that can pass the validation rules and one that can't.  This is a brittle solution though, it introduces a high degree of coupling between the `Example.save/1` tests and the implementation of `Example.valid?/1`.  

A more robust approach is simply to patch out the call to `Example.valid?/1`.  When we want to test that a valid thing gets saved, we don't have to jump through hoops to get `Example.valid?/1` to return true, we can just patch it and tell it to return true.  When someone comes along and changes the validation rules in `Example.valid?/1` it won't break our `Example.save/1` tests, it might break the tests for `Example.valid?/1` but that's a much better outcome because the test breaking is directly related to the code being changed.

Additionally, in a unit test we would want to isolate the unit from the database.  Our `Example.do_save/1` method wants to actually write to a database, but this is an implementation detail as far as `Example.save/1` is concerned.  A common approach in unit testing is to replace external dependencies, like APIs and Databases, with Fakes.  

A Fake DB could be as complex another copy of the schema actually running on the real database software that's isolated for test data or as simple as an in memory map.  In this style of testing, the test author can let the code read and write from the fake datastore and then query to make sure the datastore is in the appropriate state.  This approach "over tests" the datastore, which is likely already well tested.  A simpler approach is to simply patch out `Example.do_save/1` since we only care that it gets called and it's correct functioning should be guaranteed by tests that directly test that function.

With Patch, we **can** mock these functions and have the mocks be effective even though the module is using the common local call pattern.

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  use Patch

  describe "save/1" do
    test "valid things will be saved" do
      # Make everything valid
      patch(Example, :valid?, true)

      # Patch out do_save so we don't try to hit the database
      patch(Example, :do_save, :ok)

      assert :ok == Example.save(:thing)
      assert_called Example.do_save(:thing)
    end

    test "invalid things will not be saved" do
      # We want to refute the call to do_save/1, so let's spy the entire module
      spy(Example)

      # Make everything invalid
      patch(Example, :valid?, false)

      assert {:error, :invalid} == Example.save(:thing)
      refute_called Example.do_save(_)
    end
  end
end
```

## Patching Private Functions

Patch allows the test author to patch private functions without doing anything special.  

Given the following module

```elixir
defmodule Example do
  def public_function(a) do
    {:ok, private_function(a)}
  end

  defp private_function(a) do
    {:private, a}
  end
end
```

We can write the following test.

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  use Patch

  test "public_function/1 wraps private_function/1" do
    patch(Example, :private_function, :patched)

    assert Example.public_function(:test_argument) == {:ok, :patched}
  end
end
```

Since Patch guarantees that all calls to a patched function return the mock value, this works as expected.

Private functions can be patched just like a public function, but unless they are exposed via `expose/2` they don't become public.  This means that any other code in the project that might have mistakenly made a call to `Example.private_function/1` will fail under test because the visibility is still private.  

To make a private function public, read on to the next section.

## Testing Private Functions

Private functions frequently go untested because they are difficult to test.  Developers are faced with a few options when they have a private function.

1.  Don't test the private function.
2.  Test the private function circuitously by calling some public functions.
3.  Make a public wrapper for the private function and test that.
4.  Change the visibility to public and put a comment with some form of, "This is public just for testing, this function should be treated as though it's private."

Patch provides a new mechanism for testing private functions, `expose/2`.

With `expose/2` the test author can expose any private function to the tests as though it's public.  Here's an example.

```elixir
defmodule Example do
  def public_function(arg) do
    value = private_function(arg)

    if value < 100 do
      :small
    else
      :large
    end
  end

  ## Private

  defp private_function(arg) when arg < 20 do
    arg * 1000
  end

  defp private_function(arg) when arg < 80 do
    arg - 3
  end

  defp private_function(arg) do 
    Integer.floor_div(arg, 2)
  end
end
```

Testing `public_function/1` gives us a very coarse measure of if the `private_function/1` logic is working correctly.

It would be great if we could expose `private_function/1` to be able to more directly test this unit. 

Here's how we can expose this function for testing via `expose/2`.  Calling an exposed functions will be flagged by the 
Elixir Compiler as a warning, since the exposure happens at runtime not compile-time.  To suppress these warnings, the
`private/1` macro is provided, just wrap the call to the exposed function with `private/1`.

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  use Patch

  describe "private_function/1" do
    test "values less than 20 get magnified by 1000" do
      expose(Example, private_function: 1)

      assert private(Example.private_function(10)) == 10_000
    end

    test "values betwen 20 and 80 are reduced by 3" do
      expose(Example, private_function: 1)

      assert private(Example.private_function(50)) == 47
    end

    test "values greater than or equal to 80 are halved" do
      expose(Example, private_function: 1)

      assert private(Example.private_function(120)) == 60
    end
  end
end
```

## How does this all work?

Check out the documentation for `Patch.Mock.Code` for more details on how this is accomplished.
