defmodule Patch do
  @moduledoc """
  Patch - Ergonomic Mocking for Elixir

  Patch makes it easy to mock one or more functions in a module returning a value or executing
  custom logic.  Patches and Spies allow tests to assert or refute that function calls have been
  made.

  Using Patch is as easy as adding a single line to your test case.

  ```elixir
  use Patch
  ```

  After this all the patch functions will be available, see the README and function documentation
  for more details.
  """

  alias Patch.Mock.Naming
  alias Patch.Mock.Value
  import Value
  require Value

  ## Exceptions

  defmodule MissingCall do
    defexception [:message]
  end

  defmodule UnexpectedCall do
    defexception [:message]
  end

  ## Macros / Assertions

  defmacro __using__(_) do
    quote do
      require unquote(__MODULE__)
      import unquote(__MODULE__)
      import Patch.Mock.Value

      setup do
        start_supervised!(Patch.Supervisor)
        :ok
      end
    end
  end

  defmacro assert_called(call) do
    {module, function, args} = Macro.decompose_call(call)

    quote do
      unless Patch.Mock.called?(unquote(module), unquote(function), unquote(args)) do
        calls =
          unquote(module)
          |> Patch.Mock.history()
          |> Patch.Mock.History.entries()
          |> Enum.with_index(1)
          |> Enum.map(fn {{f, a}, i} ->
            "#{i}. #{inspect(unquote(module))}.#{f}(#{
              a |> Enum.map(&Kernel.inspect/1) |> Enum.join(", ")
            })"
          end)

        calls =
          case calls do
            [] ->
              "   [No Calls Received]"

            _ ->
              Enum.join(calls, "\n")
          end

        call_args = unquote(args) |> Enum.map(&Kernel.inspect/1) |> Enum.join(", ")

        message = """
        \n
        Expected but did not receive the following call:

           #{inspect(unquote(module))}.#{to_string(unquote(function))}(#{call_args})

        Calls which were received:

        #{calls}
        """

        raise MissingCall, message: message
      end
    end
  end

  defmacro refute_called(call) do
    {module, function, args} = Macro.decompose_call(call)

    quote do
      if Patch.Mock.called?(unquote(module), unquote(function), unquote(args)) do
        calls =
          unquote(module)
          |> Patch.Mock.history()
          |> Patch.Mock.History.entries()
          |> Enum.with_index(1)
          |> Enum.map(fn {{f, a}, i} ->
            "#{i}. #{inspect(unquote(module))}.#{f}(#{
              a |> Enum.map(&Kernel.inspect/1) |> Enum.join(", ")
            })"
          end)
          |> Enum.join("\n")

        call_args = unquote(args) |> Enum.map(&Kernel.inspect/1) |> Enum.join(", ")

        message = """
        \n
        Unexpected call received:

           #{inspect(unquote(module))}.#{to_string(unquote(function))}(#{call_args})

        Calls which were received:

        #{calls}
        """

        raise UnexpectedCall, message: message
      end
    end
  end

  @doc """
  Asserts that the function has been called with any arity call
  """
  @spec assert_any_call(module :: module(), function :: atom()) :: nil
  def assert_any_call(module, function) do
    unless Patch.Mock.called?(module, function) do
      message = """
      \n
      Expected any call received:

        #{inspect(module)}.#{to_string(function)}

      No calls found
      """

      raise MissingCall, message: message
    end
  end

  @doc """
  Refutes that the function has been called with any arity call
  """
  @spec refute_any_call(module :: module(), function :: atom()) :: nil
  def refute_any_call(module, function) do
    if Patch.Mock.called?(module, function) do
      calls =
        module
        |> Patch.Mock.history()
        |> Patch.Mock.History.entries()
        |> Enum.with_index(1)
        |> Enum.map(fn {{_, args}, i} ->
          "#{i}. #{inspect(module)}.#{to_string(function)}(#{
            args |> Enum.map(&Kernel.inspect/1) |> Enum.join(", ")
          })"
        end)

      message = """
      \n
      Unexpected call received, expected no calls:

        #{inspect(module)}.#{to_string(function)}

      Calls which were received:

      #{calls}
      """

      raise UnexpectedCall, message: message
    end
  end

  ## Functions

  @spec expose(module :: module, exposes :: Patch.Mock.Code.exposes()) :: :ok
  def expose(module, exposes) do
    {:ok, _} = Patch.Mock.module(module, exposes: exposes)
    :ok
  end

  @doc """
  Fakes out a module with an alternative implementation.

  The real module can still be accessed with `real/1`.

  For example, if your project has the module `Example.Datastore` and there's a fake available in the testing
  environment named `Example.Test.InMemoryDatastore`  the following table describes which calls are executed by which
  code before and after faking with the following call.

  ```elixir
  fake(Example.Datastore, Example.Test.InMemoryDatastore)
  ```

  | Calling Code                         | Responding Module before fake/2      | Responding Module after fake/2       |
  |--------------------------------------|--------------------------------------|--------------------------------------|
  | Example.Datastore.get/1              | Example.Datastore.get/1              | Example.Test.InMemoryDatastore.get/1 |
  | Example.Test.InMemoryDatastore.get/1 | Example.Test.InMemoryDatastore.get/1 | Example.Test.InMemoryDatastore.get/1 |
  | real(Example.Datastore).get/1        | (UndefinedFunctionError)             | Example.Datastore.get/1              |

  The fake module can use the renamed module to access the original implementation.
  """
  @spec fake(real_module :: module(), fake_module :: module()) :: :ok
  def fake(real_module, fake_module) do
    {:ok, _} = Patch.Mock.module(real_module)

    real_functions = Patch.Reflection.find_functions(real_module)
    fake_functions = Patch.Reflection.find_functions(fake_module)

    Enum.each(fake_functions, fn {name, arity} ->
      is_real_function? = Enum.any?(real_functions, &match?({^name, ^arity}, &1))

      if is_real_function? do
        patch(
          real_module,
          name,
          callable(fn args ->
            apply(fake_module, name, args)
          end, :list)
        )
      end
    end)
  end

  @doc """
  Convenience function for updating the state of a running process.

  Uses the `Access` module to traverse the state structure according to the given `keys`.

  Structs have special handling so that they can be updated without having to implement the
  `Access` behavior.
  """
  @spec inject(target :: GenServer.server(), keys :: [term(), ...], value :: term()) :: term()
  def inject(target, keys, value) do
    :sys.replace_state(target, fn
      %struct{} = state ->
        updated =
          state
          |> Map.from_struct()
          |> put_in(keys, value)

        struct(struct, updated)

      state ->
        put_in(state, keys, value)
    end)
  end

  @doc """
  Starts a listener process.

  When used on a named process, this is sufficient to begin intercepting all messages to the named
  process.

  When used on an unnamed process, the process that is spawned will forward any messages to the
  caller and target process but any processes holding a reference to the old pid will need to be
  updated.

  `inject/3` can be used to inject a listener into a running process.
  """
  @spec listen(
          tag :: Patch.Listener.tag(),
          target :: Patch.Listener.target(),
          options :: Patch.Listener.options()
        ) :: {:ok, pid()} | {:error, :not_found}
  def listen(tag, target, options \\ []) do
    Patch.Listener.Supervisor.start_child(self(), tag, target, options)
  end

  @doc """
  Patches a function in a module

  The patched function will either always return the provided value or if a function is provided
  then the function will be called and its result returned.
  """
  @spec patch(module :: module(), function :: atom(), value :: Patch.Mock.Value.t()) ::
          Patch.Mock.Value.t()
  def patch(module, function, %value_module{} = value) when is_value(value_module) do
    {:ok, _} = Patch.Mock.module(module)
    :ok = Patch.Mock.register(module, function, value)
    value
  end

  @spec patch(module :: module(), function :: atom(), callable :: function()) :: function()
  def patch(module, function, callable) when is_function(callable) do
    patch(module, function, callable(callable))
    callable
  end

  @spec patch(module :: module(), function :: atom(), return_value) :: return_value
        when return_value: term()
  def patch(module, function, return_value) do
    patch(module, function, scalar(return_value))
    return_value
  end

  @spec real(module :: module()) :: module()
  def real(module) do
    Naming.original(module)
  end

  @doc """
  Remove any mocks or spies from the given module
  """
  @spec restore(module :: module()) :: :ok | {:error, term()}
  def restore(module) do
    Patch.Mock.restore(module)
  end

  @doc """
  Spies on the provided module

  Once a module has been spied on the calls to that module can be asserted / refuted without
  changing the behavior of the module.
  """
  @spec spy(module :: module()) :: :ok
  def spy(module) do
    {:ok, _} = Patch.Mock.module(module)
    :ok
  end




end
