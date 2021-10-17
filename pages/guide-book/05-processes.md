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

## Injecting

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
