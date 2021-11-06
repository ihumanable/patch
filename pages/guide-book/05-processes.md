# Chapter 5: Processes

Elixir code frequently runs many processes and a test author often wants to assert about the flow of messages between processes.  `Patch` provides some utilities that make listening to the messages between processes easy.

## Listeners

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

### GenServer Support

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

### Target Monitoring

Listeners will automatically monitor the target process they are listening to.  If the target process goes `:DOWN` the listener will deliver a tagged `{:DOWN, reason}` message to the test process and then exit.

## Injecting Listeners

`listen/3` works well for named processes when callers are using the name to send messages to the target process.  What should we do when callers are sending to a pid instead of a name?  This is where the `inject/4` function can be used.

`inject/4` will extract a pid out of a GenServer's state, wrap it with a listener and then replace the pid in the GenServer's state with the listener pid.

Here's a simple example, we will have 2 modules, `Target` and `Caller`.

```elixir
defmodule Target do
  use GenServer

  ## Client

  def start_link(multiplier) do
    GenServer.start_link(__MODULE__, multiplier)
  end

  def work(pid, argument) do
    GenServer.call(pid, {:work, argument})
  end

  ## Server

  def init(multiplier) do
    {:ok, multiplier}
  end

  def handle_call({:work, argument}, _from, multiplier) do
    {:reply, argument * multiplier, multiplier}
  end
end
```

Our `Target` module isn't very interested, it can do some `work/1` where the caller sends it a number and it multiplies it by the `multiplier` it was started with and returns it.

Next let's look at our `Caller`

```elixir
defmodule Caller do
  use GenServer

  defstruct [:bonus, :target_pid]

  ## Client

  def start_link(bonus, multiplier) do
    GenServer.start_link(__MODULE__, {bonus, multiplier})
  end

  def calculate(pid, argument) do
    GenServer.call(pid, {:calculate, argument})
  end

  ## Server

  def init({bonus, multiplier}) do
    {:ok, target_pid} = Target.start_link(multiplier) 

    {:ok, %__MODULE__{bonus: bonus, target_pid: target_pid}}
  end

  def handle_call({:calculate, argument}, _from, %__MODULE__{} = state) do
    multiplied = Target.work(state.target_pid, argument)
    {:reply, multiplied + state.bonus, state}
  end
end
```

Our `Caller` takes two values, a `bonus` and a `multiplier`.  It spawns a new `Target` process with the multiplier and stores the `target_pid` in its state.

The `Caller` process will send a message to the `target_pid` it has stored in its state.  

Here's how we can use `inject/4` to listen to the messages between the `Caller` process and the `Target` process.

```elixir
defmodule PatchExample do
  use ExUnit.Case
  use Patch

  test "listen to messages to Target Process" do
    bonus = 5
    multiplier = 10

    {:ok, caller_pid} = Caller.start_link(bonus, multiplier)

    inject(:target, caller_pid, [:target_pid])

    assert Caller.calculate(caller_pid, 7) == 75   # (7 * 10) + 5

    assert_receive {:target, {GenServer, :call, {:work, 7}, from}}
    assert_receive {:target, {GenServer, :reply, 70, ^from}}
  end
end
```

`inject/4` accepts the same options as `listen/3` and returns the `{:ok, listener_pid}` after successfully injecting the listener.

## Replacing State

When working with processes in test code it is sometimes necessary to change the state of a running GenServer.  Common use cases for injecting state into a GenServer are to set up some fixture data, update a configuration value, or replacing pids like in the previous section.

`replace/3` is a helper that handles some common issues when updating state.

```elixir
defmodule PatchExample do
  use ExUnit.Case
  use Patch

  test "state can be replaced" do
    {:ok, pid} = Target.start_link(:initial_value)
    
    assert :initial_value == Target.get_value(pid)

    replace(pid, [:value], :updated_value)

    assert :updated_value == Target.get_value(pid)
  end
end
```

`replace/3` accepts a `GenServer.server` a list of `keys` like one would use for `put_in/3` and then a value to inject into the processes state.

Unlike `put_in/3`, `replace/3` will work with Structs that do not implement the `Access` behaviour.  It does not support the Access functions though, just a list of keys.