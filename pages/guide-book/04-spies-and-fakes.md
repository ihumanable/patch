# Chapter 4: Spies and Fakes

In [Chapter 2: Patching](02-patching.html) and [Chapter 3: Mock Values](03-mock-values.html) we saw how we can patch functions to return particular mock values.

There are two common cases for patching that have special helpers.

## Spies

If a test wishes to assert / refute calls that happen to a module without actually changing the behavior of the module it can simply `spy/1` the module.  Spies behave identically to the original module but all calls are recorded so `assert_called/1`, `refute_called/1`, `assert_any_called/2`, and `refute_any_called/2` work as expected.

```elixir
defmodule PatchExample do
  use ExUnit.Case
  use Patch

  def example(value) do
    String.upcase(value)
  end

  test "spies can see what calls happen without changing functionality" do
    spy(String)

    assert "HELLO" == example("hello")

    assert_called String.upcase("hello")
  end
end
```

## Fakes

Sometimes we want to replace one module with another for testing, for example we might want to replace a module that connects to a real datastore with a fake that stores data in memory while providing the same API.

The `fake/2,3` functions can be used to replace one module with another.  The replacement module can be completely stand alone or can utilize the functionality of the replaced module, it will be made available through use of the `real/1` function.

```elixir
defmodule HighLatencyDatabase do
  @latency System.convert_time_unit(20, :second, :microsecond)

  def get(id) do
    {elapsed, response} = :timer.tc(fn -> Patch.real(Database).get(id) end)
    induce_latency(elapsed)
    response
  end

  defp induce_latency(elapsed) when elapsed < @latency do
    time_to_sleep = System.convert_time_unit(@latency - elapsed, :microsecond, :millisecond)
    Process.sleep(time_to_sleep)
  end

  defp induce_latency(_), do: :ok
end
```

This fake module uses the real module to actually get the record from the database and then makes sure that a minimum amount of latency, in this case 20 seconds, is introduced before returning the result.

To swap out our real Database with our fake HighLatencyDatabase in a test we can now do the following

```elixir
defmodule PatchExample do
  use ExUnit.Case
  use Patch

  def example(value) do
    String.upcase(value)
  end

  test "API raises TimeoutError when database is experiencing high latency" do
    fake(Database, HighLatencyDatabase)

    assert_raises TimeoutError, fn ->
      API.get(:user, 1)
    end
  end
end
```