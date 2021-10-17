# Super Powers

Patch provides 2 special features that no other mocking library for Elixir offers.  See the [Mockompare](https://github.com/ihumanable/mockompare) suite for a comparison of Elixir / Erlang mocking libraries.  If there is a way to accomplish the following with another library, please open an issue so this section and the comparisons can be updated.

So what are these super powers?

1.  Patch makes it possible to test your private functions without changing their visibility via the `expose/2` functionality.  
2.  Patch mocks are effective for both local and remote calls.  This means a patched function **always** resolves to the patch.

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

Here's how we can expose this function for testing via `expose/2`

```elixir
defmodule ExampleTest do
  use ExUnit.Case
  use Patch

  describe "private_function/1" do
    test "values less than 20 get magnified by 1000" do
      expose(Example, private_function: 1)

      assert Example.private_function(10) == 10_000
    end

    test "values betwen 20 and 80 are reduced by 3" do
      expose(Example, private_function: 1)

      assert Example.private_function(50) == 47
    end

    test "values greater than or equal to 80 are halved" do
      expose(Example, private_function: 1)

      assert Example.private_function(120) == 60
    end
  end
end
```

## Local and Remote Calls

Next up is the issue of local vs remote calls.  In Elixir we have two different ways to call a function, local call vs remote call.

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
    rules = DB.fetch(validation_rules_for, thing)
    Enum.all?(rules, &Rule.valid?(&1, thing))
  end

  defp do_save(thing) do
    DB.insert(thing)
  end
end
```

In a unit test we would want to isolate the unit from the database, we might not want to create a fixture that can actually pass realistic validation if we just want to test the high level logic of "valid gets saved, invalid gets an error."

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
      refute_called Example.do_save(:_)
    end
  end
end
```

## How does this all work?

Check out the documentation for `Patch.Mock.Code` for more details on how this is accomplished.
