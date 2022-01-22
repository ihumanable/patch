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

  After this all the patch functions will be available, see the function documentation for
  details.
  """
  alias Patch.Mock
  alias Patch.Mock.Naming
  alias Patch.Mock.Value
  import Value
  require Value

  ## Exceptions

  defmodule ConfigurationError do
    defexception [:message]
  end

  defmodule InvalidAnyCall do
    defexception [:message]
  end

  defmodule MissingCall do
    defexception [:message]
  end

  defmodule UnexpectedCall do
    defexception [:message]
  end

  defmacro __using__(_) do
    quote do
      require unquote(__MODULE__)
      import unquote(__MODULE__)
      import Patch.Mock.Value, except: [advance: 1, next: 2]

      require Patch.Assertions
      require Patch.Macro
      require Patch.Mock
      require Patch.Mock.History.Tagged


      setup do
        start_supervised!(Patch.Supervisor)

        on_exit(fn ->
          Patch.Mock.Code.Freezer.empty()
        end)

        :ok
      end
    end
  end

  @doc """
  Asserts that the given module and function has been called with any arity.

  ```elixir
  patch(Example, :function, :patch)

  assert_any_call Example.function   # fails

  Example.function(1, 2, 3)

  assert_any_call Example.function   # passes
  ```
  """
  @spec assert_any_call(call :: Macro.t()) :: Macro.t()
  defmacro assert_any_call(call) do
    {module, function, arguments} = Macro.decompose_call(call)

    unless Enum.empty?(arguments) do
      raise InvalidAnyCall, message: "assert_any_call/1 does not support arguments"
    end

    quote do
      Patch.Assertions.assert_any_call(unquote(module), unquote(function))
    end
  end

  @doc """
  Asserts that the given module and function has been called with any arity.

  ```elixir
  patch(Example, :function, :patch)

  assert_any_call Example, :function   # fails

  Example.function(1, 2, 3)

  assert_any_call Example, :function   # passes
  ```

  This function exists for advanced use cases where the module or function are not literals in the
  test code.  If they are literals then `assert_any_call/1` should be preferred.
  """
  @spec assert_any_call(module :: module(), function :: atom()) :: nil
  defdelegate assert_any_call(module, function), to: Patch.Assertions

  @doc """
  Given a call will assert that a matching call was observed by the patched function.

  This macro fully supports patterns and will perform non-hygienic binding similar to ExUnit's
  `assert_receive/3` and `assert_received/2`.

  ```elixir
  patch(Example, :function, :patch)

  Example.function(1, 2, 3)

  assert_called Example.function(1, 2, 3)   # passes
  assert_called Example.function(1, _, 3)   # passes
  assert_called Example.function(4, 5, 6)   # fails
  assert_called Example.function(4, _, 6)   # fails
  ```
  """
  @spec assert_called(Macro.t()) :: Macro.t()
  defmacro assert_called(call) do
    quote do
      Patch.Assertions.assert_called(unquote(call))
    end
  end

  @doc """
  Given a call will assert that a matching call was observed exactly the number of times provided
  by the patched function.

  This macro fully supports patterns and will perform non-hygienic binding similar to ExUnit's
  `assert_receive/3` and `assert_received/2`.  Any binds will bind to the latest matching call
  values.

  ```elixir
  patch(Example, :function, :patch)

  Example.function(1, 2, 3)

  assert_called Example.function(1, 2, 3), 1   # passes
  assert_called Example.function(1, _, 3), 1   # passes

  Example.function(1, 2, 3)

  assert_called Example.function(1, 2, 3), 2   # passes
  assert_called Example.function(1, _, 3), 2   # passes
  ```
  """
  @spec assert_called(call :: Macro.t(), count :: Macro.t()) :: Macro.t()
  defmacro assert_called(call, count) do
    quote do
      Patch.Assertions.assert_called(unquote(call), unquote(count))
    end
  end

  @doc """
  Given a call will assert that a matching call was observed exactly once by the patched function.

  This macro fully supports patterns and will perform non-hygienic binding similar to ExUnit's
  `assert_receive/3` and `assert_received/2`.

  ```elixir
  patch(Example, :function, :patch)

  Example.function(1, 2, 3)

  assert_called_once Example.function(1, 2, 3)   # passes
  assert_called_once Example.function(1, _, 3)   # passes

  Example.function(1, 2, 3)

  assert_called_once Example.function(1, 2, 3)   # fails
  assert_called_once Example.function(1, _, 3)   # fails
  ```
  """
  @spec assert_called_once(call :: Macro.t()) :: Macro.t()
  defmacro assert_called_once(call) do
    quote do
      Patch.Assertions.assert_called_once(unquote(call))
    end
  end


  @doc """
  Expose can be used to turn private functions into public functions for the
  purpose of testing them.

  To expose every private function as a public function, pass the sentinel value `:all`.

  ```elixir
  expose(Example, :all)
  ```

  Otherwise pass a `Keyword.t(arity)` of the functions to expose.

  For example, if one wanted to expose `private_function/1` and `private_function/2`.

  ```elixir
  expose(Example, [private_function: 1, private_function: 2])
  ```

  After exposing a function, attempting to call the exposed function will cause the Elixir
  Compiler to flag calls to exposed functions as a warning.  There are companion macros
  `private/1` and `private/2` that test authors can wrap their calls with to prevent warnings.
  """
  @spec expose(module :: module, exposes :: Patch.Mock.exposes()) :: :ok | {:error, term()}
  def expose(module, exposes) do
    Mock.expose(module, exposes)
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
    {:ok, _} = Mock.module(real_module)

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

  @spec inject(
          tag :: Patch.Listener.tag(),
          target :: Patch.Listener.target(),
          keys :: [term(), ...],
          options :: [Patch.Listener.option()]
        ) :: {:ok, pid()} | {:error, :not_found} | {:error, :invalid_keys}
  def inject(tag, target, keys, options \\ []) do
    state = :sys.get_state(target)

    case Patch.Access.fetch(state, keys) do
      {:ok, subject} ->
        with {:ok, listener} <- listen(tag, subject, options) do
          replace(target, keys, listener)
          {:ok, listener}
        end

      :error ->
        {:error, :invalid_keys}
    end
  end

  @doc """
  Get all the observed calls to a module.  These calls are expressed as a `{name, argument}` tuple
  and can either be provided in ascending (oldest first) or descending (newest first) order by
  providing a sorting of `:asc` or `:desc`, respectively.

  ```elixir
  Example.example(1, 2, 3)
  Example.function(:a)

  assert history(Example) == [{:example, [1, 2, 3]}, {:function, [:a]}]
  assert history(Example, :desc) == [{:function, [:a]}, {:example, [1, 2, 3]}]
  ```

  For asserting or refuting that a call happened the `assert_called/1`, `assert_any_call/2`,
  `refute_called/1`, and `refute_any_call/2` functions provide a more convenient API.
  """
  @spec history(module :: module(), sorting :: :asc | :desc) :: [Mock.History.entry()]
  def history(module, sorting \\ :asc) do
    module
    |> Mock.history()
    |> Mock.History.entries(sorting)
  end

  @doc """
  Starts a listener process.

  Each listener should provide a unique `tag` that will be used when forwarding messages to the
  test process.

  When used on a named process, this is sufficient to begin intercepting all messages to the named
  process.

  ```elixir
  listen(:listener, Example)
  ```

  When used on an unnamed process, the process that is spawned will forward any messages to the
  caller and target process but any processes holding a reference to the old pid will need to be
  updated.

  `inject/3` can be used to inject a listener into a running process.

  ```elixir
  {:ok, listener} = listen(:listener, original)
  inject(target, :original, listener)
  ```
  """
  @spec listen(
          tag :: Patch.Listener.tag(),
          target :: Patch.Listener.target(),
          options :: [Patch.Listener.option()]
        ) :: {:ok, pid()} | {:error, :not_found}
  def listen(tag, target, options \\ []) do
    Patch.Listener.Supervisor.start_child(self(), tag, target, options)
  end

  @doc """
  Patches a function in a module

  When called with a function the function will be called instead of the original function and its
  results returned.

  ```elixir
  patch(Example, :function, fn arg -> {:mock, arg} end)

  assert Example.function(:test) == {:mock, :test}
  ```

  To handle multiple arities create a `callable/2` with the `:list` option and the arguments will
  be wrapped to the function in a list.

  ```elixir
  patch(Example, :function, callable(fn
    [] ->
      :zero

    [a] ->
      {:one, a}

    [a, b] ->
      {:two, a, b}
  end, :list))

  assert Example.function() == :zero
  assert Example.function(1) == {:one, 1}
  assert Example.function(1, 2) == {:two, 1, 2}
  ```

  To provide a function as a literal value to be returned, use the `scalar/1` function.

  ```elixir
  patch(Example, :function, scalar(fn arg -> {:mock, arg} end))

  callable = Example.function()
  assert callable.(:test) == {:mock, :test}
  ```

  The function `cycle/1` can be given a list which will be infinitely cycled when the function is
  called.

  ```elixir
  patch(Example, :function, cycle([1, 2, 3]))

  assert Example.function() == 1
  assert Example.function() == 2
  assert Example.function() == 3
  assert Example.function() == 1
  assert Example.function() == 2
  assert Example.function() == 3
  assert Example.function() == 1
  ```

  The function `raises/1` can be used to `raise/1` a `RuntimeError` when the function is called.

  ```elixir
  patch(Example, :function, raises("patched"))

  assert_raise RuntimeError, "patched", fn ->
    Example.function()
  end
  ```

  The function `raises/2` can be used to `raise/2` any exception with any attributes when the function
  is called.

  ```elixir
  patch(Example, :function, raises(ArgumentError, message: "patched"))

  assert_raise ArgumentError, "patched", fn ->
    Example.function()
  end
  ```

  The function `sequence/1` can be given a list which will be used until a single value is
  remaining, the remaining value will be returned on all subsequent calls.

  ```elixir
  patch(Example, :function, sequence([1, 2, 3]))

  assert Example.function() == 1
  assert Example.function() == 2
  assert Example.function() == 3
  assert Example.function() == 3
  assert Example.function() == 3
  assert Example.function() == 3
  assert Example.function() == 3
  ```

  The function `throws/1` can be given a value to `throw/1` when the function is called.

  ```elixir
  patch(Example, :function, throws(:patched))

  assert catch_throw(Example.function()) == :patched
  ```

  Any other value will be returned as a literal scalar value when the function is called.

  ```elixir
  patch(Example, :function, :patched)

  assert Example.function() == :patched
  ```
  """
  @spec patch(module :: module(), function :: atom(), value :: Value.t()) :: Value.t()
  def patch(module, function, %value_module{} = value) when is_value(value_module) do
    {:ok, _} = Patch.Mock.module(module)
    :ok = Patch.Mock.register(module, function, value)
    value
  end

  @spec patch(module :: module(), function :: atom(), callable) :: callable when callable: function()
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

  @doc """
  Suppress warnings for using exposed private functions in tests.

  Patch allows you to make a private function public via the `expose/2` function.  Exposure
  happens dynamically at test time. The Elixir Compiler will flag calls to exposed functions as a
  warning.

  One way around this is to change the normal function call into an `apply/3` but this is
  cumbersome and makes tests harder to read.

  This macro just rewrites a normal looking call into an `apply/3` so the compiler won't complain
  about calling an exposed function.

  ```elixir
  expose(Example, :all)

  patch(Example, :private_function, :patched)

  assert Example.private_function() == :patched   # Compiler will warn about call to undefined function
  assert apply(Example, :private_function, []) == :patched   # Compiler will not warn
  assert private(Example.private_function()) == :patched     # Same as previous line, but looks nicer.
  ```
  """
  @spec private(Macro.t()) :: Macro.t()
  defmacro private(call) do
    {module, function, arguments} = Macro.decompose_call(call)

    quote do
      apply(unquote(module), unquote(function), unquote(arguments))
    end
  end

  @doc """
  Suppress warnings for using exposed private functions in tests.

  Patch allows you to make a private function public via the `expose/2` function.  Exposure
  happens dynamically at test time. The Elixir Compiler will flag calls to exposed functions as a
  warning.

  One way around this is to change the normal function call into an `apply/3` but this is
  cumbersome and makes tests harder to read.

  This macro just rewrites a normal looking call into an `apply/3` so the compiler won't complain
  about calling an exposed function, with support for pipelines.

  ```elixir
  expose(Example, :all)

  example_that_warns =
    Example.new()
    |> Example.private_function()  # Compiler will warn about call to undefined function


  example_that_does_not_warn
    Example.new()
    |> private(Example.private_function())  # Compiler will not warn and Example.new() is provided
                                            # as the first argument to Example.private_function/1
  ```
  """
  @spec private(Macro.t(), Macro.t()) :: Macro.t()
  defmacro private(argument, call) do
    {module, function, arguments} = Macro.decompose_call(call)

    quote do
      apply(unquote(module), unquote(function), [unquote(argument) | unquote(arguments)])
    end
  end

  @doc """
  Gets the real module name for a fake.

  This is useful for Fakes that want to defer some part of the functionality back to the real
  module.

  ```elixir
  def Example do
    def calculate(a) do
      # ...snip some complex calculations...
      result
    end
  end

  def Example.Fake do
    import Patch, only: [real: 1]

    def calculate(a) do
      real_result = real(Example).calculate(a)

      {:fake, real_result}
    end
  end
  """
  @spec real(module :: module()) :: module()
  def real(module) do
    Naming.original(module)
  end

  @doc """
  Refutes that the given module and function has been called with any arity.

  ```elixir
  patch(Example, :function, :patch)

  refute_any_call Example.function   # passes

  Example.function(1, 2, 3)

  refute_any_call Example.function   # fails
  ```
  """
  @spec refute_any_call(call :: Macro.t()) :: Macro.t()
  defmacro refute_any_call(call) do
    {module, function, arguments} = Macro.decompose_call(call)

    unless Enum.empty?(arguments) do
      raise InvalidAnyCall, message: "refute_any_call/1 does not support arguments"
    end

    quote do
      Patch.Assertions.refute_any_call(unquote(module), unquote(function))
    end
  end

  @doc """
  Refutes that the given module and function has been called with any arity.

  ```elixir
  patch(Example, :function, :patch)

  refute_any_call Example, :function   # passes

  Example.function(1, 2, 3)

  refute_any_call Example, :function   # fails
  ```

  This function exists for advanced use cases where the module or function are not literals in the
  test code.  If they are literals then `refute_any_call/1` should be preferred.
  """
  @spec refute_any_call(module :: module(), function :: atom()) :: nil
  defdelegate refute_any_call(module, function), to: Patch.Assertions

  @doc """
  Given a call will refute that a matching call was observed by the patched function.

  This macro fully supports patterns.

  ```elixir
  patch(Example, :function, :patch)

  Example.function(1, 2, 3)

  refute_called Example.function(4, 5, 6)   # passes
  refute_called Example.function(4, _, 6)   # passes
  refute_called Example.function(1, 2, 3)   # fails
  refute_called Example.function(1, _, 3)   # fails
  ```
  """
  @spec refute_called(call :: Macro.t()) :: Macro.t()
  defmacro refute_called(call) do
    quote do
      Patch.Assertions.refute_called(unquote(call))
    end
  end

  @doc """
  Given a call will refute that a matching call was observed exactly the number of times provided
  by the patched function.

  This macro fully supports patterns.

  ```elixir
  patch(Example, :function, :patch)

  Example.function(1, 2, 3)

  refute_called Example.function(1, 2, 3), 2   # passes
  refute_called Example.function(1, _, 3), 2   # passes

  Example.function(1, 2, 3)

  refute_called Example.function(1, 2, 3), 1   # passes
  refute_called Example.function(1, _, 3), 1   # passes
  ```
  """
  @spec refute_called(call :: Macro.t(), count :: Macro.t()) :: Macro.t()
  defmacro refute_called(call, count) do
    quote do
      Patch.Assertions.refute_called(unquote(call), unquote(count))
    end
  end

  @doc """
  Given a call will refute that a matching call was observed exactly once by the patched function.

  This macro fully supports patterns.

  ```elixir
  patch(Example, :function, :patch)

  Example.function(1, 2, 3)

  refute_called_once Example.function(1, 2, 3)   # fails
  refute_called_once Example.function(1, _, 3)   # fails

  Example.function(1, 2, 3)

  refute_called_once Example.function(1, 2, 3)   # passes
  refute_called_once Example.function(1, _, 3)   # passes
  ```
  """
  @spec refute_called_once(call :: Macro.t()) :: Macro.t()
  defmacro refute_called_once(call) do
    quote do
      Patch.Assertions.refute_called_once(unquote(call))
    end
  end

  @doc """
  Convenience function for replacing part of the state of a running process.

  Uses the `Access` module to traverse the state structure according to the given `keys`.

  Structs have special handling so that they can be updated without having to implement the
  `Access` behavior.

  For example to replace the key `:key` in the map found under the key `:map` with the value
  `:replaced`

  ```elixir
  replace(target, [:map, :key], :replaced)
  ```
  """
  @spec replace(target :: GenServer.server(), keys :: [term(), ...], value :: term()) :: term()
  def replace(target, keys, value) do
    :sys.replace_state(target, &Patch.Access.put(&1, keys, value))
  end

  @doc """
  Remove any mocks or spies from the given module

  ```elixir
  original = Example.example()

  patch(Example, :example, :patched)
  assert Example.example() == :patched

  restore(Example)
  assert Example.example() == original
  ```
  """
  @spec restore(module :: module()) :: :ok | {:error, term()}
  def restore(module) do
    Mock.restore(module)
  end

  @doc """
  Remove any patches associated with a function in a module.

  ```elixir
  original = Example.example()

  patch(Example, :example, :example_patch)
  patch(Example, :other, :other_patch)

  assert Example.example() == :example_patch
  assert Example.other() == :other_patch

  restore(Example, :example)

  assert Example.example() == original
  assert Example.other() == :other_patch
  """
  @spec restore(module :: module(), name :: atom()) :: :ok | {:error, term()}
  def restore(module, name) do
    Mock.restore(module, name)
  end

  @doc """
  Spies on the provided module

  Once a module has been spied on the calls to that module can be asserted / refuted without
  changing the behavior of the module.

  ```elixir
  spy(Example)

  Example.example(1, 2, 3)

  assert_called Example.example(1, 2, 3)   # passes
  """
  @spec spy(module :: module()) :: :ok
  def spy(module) do
    {:ok, _} = Mock.module(module)
    :ok
  end
end
