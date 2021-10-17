# Guide Book

## Patching Code

Patch provides a number of utilities for replacing functionality at test-time.

### Patching

When a module is patched, the patched function will return the value provided.

```elixir
defmodule PatchExample do
  use ExUnit.Case
  use Patch

  test "functions can be patched to return a specified value" do
    # Assertion passes before patching
    assert "HELLO" = String.upcase("hello")

    # The function can be patched to return a static value
    patch(String, :upcase, :patched_return_value)

    # Assertion passes after patching
    assert :patched_return_value == String.upcase("hello")  
  end
end
```

Modules can also be patched to run custom logic instead of returning a static value

```elixir
defmodule PatchExample do
  use ExUnit.Case
  use Patch

  test "functions can be patched with a replacement function" do
    # Assertion passes before patching
    assert "HELLO" = String.upcase("hello")

    # The function can be patched to run custom code
    patch(String, :upcase, fn s -> String.length(s) end)

    # Assertion passes after patching
    assert 5 == String.upcase("hello")
  end
end
```

#### Patching Ergonomics

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

### Asserting / Refuting Calls

After a patch is applied, tests can assert that an expected call has occurred by using the `assert_called` macro.

```elixir
defmodule PatchExample do
  use ExUnit.Case
  use Patch

  test "asserting calls on a patch" do
    patch(String, :upcase, :patched_return_value)

    assert :patched_return_value = String.upcase("hello")   # Assertion passes after patching

    assert_called String.upcase("hello")                    # Assertion passes after call
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
    patch(String, :upcase, :patched_return_value)

    assert "h" == String.at("hello", 0)

    refute_called String.upcase("hello")
  end
end
```

#### Multiple Arities

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

### Spies

If a test wishes to assert / refute calls that happen to a module without actually changing the behavior of the module it can simply `spy/1` the module.  Spies behave identically to the original module but all calls and return values are recorded so `assert_called/1`, `refute_called/1`, `assert_any_called/2`, and `refute_any_called/2` work as expected.

```elixir
defmodule PatchExample do
  use ExUnit.Case
  use Patch

  def example(value) do
    String.upcase(value)
  end

  test "spies can see what calls happen without changing functionality" do
    spy(String)

    assert "HELLO" = example("hello")

    assert_called String.upcase("hello")
  end
end
```
### Fakes

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

## Working with Processes

Elixir code frequently runs many processes and a test author often wants to assert about the flow of messages between processes.  Patch provides some utilities that make listening to the messages between processes easy.

### Listeners

Listeners are processes that sit between the sender process and the target process.  The listener process will send a copy of every message to the test process so it can use ExUnit's built in `assert_receive`, `assert_received`, `refute_receive`, and `refute_received` functions.

Listeners are especially useful when working with named processes since they will automatically unregister the named process and take its place.  For anonymous processes the `inject/3` function is provided to assist in injecting listeners into other processes or the listener can be used in place of the target process when starting consumer processes. 

Listeners are started with the `listen/3` function and each have a `tag` so that the test process can differentiate which listener has delivered which message.

```elixir
defmodule PatchExample do
  use ExUnit.Case
  use Patch

  test "sharded read replication" do
    listen(:shard_a_leader, ShardALeader)
    listen(:shard_a_replica_1, ShardAReplica1)
    listen(:shard_a_replica_2, ShardAReplica2)
    
    listen(:shard_b_leader, ShardBLeader)
    listen(:shard_b_replica_1, ShardBReplica1)
    listen(:shard_b_replica_2, ShardBReplica2)

    send(ShardALeader, {:write, :some_value})

    # Assert the leader gets the message
    assert_receive {:shard_a_leader, {:write, :some_value}}

    # Assert that the replicas for Shard A get the message too
    assert_receive {:shard_a_replica_1, {:write, :some_value}}
    assert_receive {:shard_a_replica_2, {:write, :some_value}}
    
    # Assert that Shard A does not try to replicate to Shard B
    refute_receive {:shard_b_leader, {:write, :some_value}}
    refute_receive {:shard_b_replica_1, {:write, :some_value}}
    refute_receive {:shard_b_replica_2, {:write, :some_value}}
  end
end
```

#### GenServer Support

Listeners have special support for GenServers.  By default a listener will provide the test process with all calls, replies, casts, and messages. 

Given a listener with the tag `:tag` the messages from a GenServer are formatted as follows.

| Client Code                   | Message to Test Process                      |
|:------------------------------|:---------------------------------------------|
| GenServer.call(pid, :message) | `{:tag, {GenServer, :call, :message, from}}` |
|  # if capture_replies = true  | `{:tag, {GenServer, :reply, result, from}}`  |
| GenServer.cast(pid, :message) | `{:tag, {GenServer, :cast, :message}}`       |

During a `GenServer.call/3` the listener sits between the client and the server and reports back information to the test process.

```text
     .------------.          .------.                .--------.                .------.
     |Test Process|          |client|                |listener|                |server|
     '------------'          '------'                '--------'                '------'
           |                    | GenServer.call(message)|                        |    
           |                    | ----------------------->                        |    
           |                    |                        |                        |    
           |      {GenServer, :call, message, from}      |                        |    
           | <- - - - - - - - - - - - - - - - - - - - - -                         |    
           |                    |                        |                        |    
           |                    |                        | GenServer.call(message)|    
           |                    |                        | ----------------------->    
           |                    |                        |                        |    
           |                    |                        |          reply         |    
           |                    |                        | <-----------------------    
           |                    |                        |                        |    
           |       {GenServer, :reply, reply, from}      |                        |    
           | <- - - - - - - - - - - - - - - - - - - - - -                         |    
           |                    |                        |                        |    
           |                    |          reply         |                        |    
           |                    | <-----------------------                        |    
     .------------.          .------.                .--------.                .------.
     |Test Process|          |client|                |listener|                |server|
     '------------'          '------'                '--------'                '------'`
```

`GenServer.call/3` allows the client to set a timeout, an amount of time to wait for the server to response.  The listener does not know how long the original client will wait for a timeout, the test author can provide a `:timeout` option when spawning the listener to control how long the listener will wait for its `GenServer.call/3`.  By default the listener will wait 5000ms for each call, the default for `GenServer.call/2`.

If the test doesn't require the listener to capture replies to `GenServer.call` then the `:capture_replies` option can be set to false.  When this option is false the listener will simply forward the call onto the server.  Refer to the following diagram for details on how this works.

```text
     .------------.          .------.                .--------.                          .------.
     |Test Process|          |client|                |listener|                          |server|
     '------------'          '------'                '--------'                          '------'
           |                    | GenServer.call(message)|                                  |    
           |                    | ----------------------->                                  |    
           |                    |                        |                                  |    
           |      {GenServer, :call, message, from}      |                                  |    
           | <- - - - - - - - - - - - - - - - - - - - - -                                   |    
           |                    |                        |                                  |    
           |                    |                        | send(:"$gen_call", from, message)|    
           |                    |                        | --------------------------------->    
           |                    |                        |                                  |    
           |                    |                        |  reply                           |    
           |                    | <----------------------------------------------------------    
     .------------.          .------.                .--------.                          .------.
     |Test Process|          |client|                |listener|                          |server|
     '------------'          '------'                '--------'                          '------'
```

#### Target Monitoring

Listeners will automatically monitor the target process they are listening to.  If the target process goes `:DOWN` the listener will deliver a tagged `{:DOWN, reason}` message to the test process and then exit.

### Injecting

When working with processes in test code it is sometimes necessary to change the state of a running GenServer.  Common use cases for injecting state into a GenServer are to set up some fixture data, update a configuration value, or replace a target pid with a listener from the previous section.

`inject/3` is a helper that handles some common issues when updating state.

```elixir
defmodule PatchExample do
  use ExUnit.Case
  use Patch

  test "state can be updated" do
    {:ok, pid} = Target.start_link(:initial_value)
    
    assert :initial_value == Target.get_value(pid)

    inject(pid, [:value], :updated_value)

    assert :updated_value == Target.get_value(pid)
  end
end
```

`inject/3` accepts a `GenServer.server` a list of `keys` like one would use for `put_in` and then a value to inject into the processes state.
