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

      setup do
        on_exit(fn ->
          :meck.unload()
        end)
      end
    end
  end

  defmacro assert_called({{:., _, [module, function]}, _, args}) do
    quote do
      value = :meck.called(unquote(module), unquote(function), unquote(args))

      unless value do
        calls =
          unquote(module)
          |> :meck.history()
          |> Enum.with_index(1)
          |> Enum.map(fn {{_, {m, f, a}, ret}, i} ->
            "#{i}. #{inspect(m)}.#{f}(#{a |> Enum.map(&Kernel.inspect/1) |> Enum.join(", ")}) -> #{
              inspect(ret)
            }"
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

  defmacro refute_called({{:., _, [module, function]}, _, args}) do
    quote do
      value = :meck.called(unquote(module), unquote(function), unquote(args))

      if value do
        calls =
          unquote(module)
          |> :meck.history()
          |> Enum.with_index(1)
          |> Enum.map(fn {{_, {m, f, a}, ret}, i} ->
            "#{i}. #{inspect(m)}.#{f}(#{a |> Enum.map(&Kernel.inspect/1) |> Enum.join(", ")}) -> #{
              inspect(ret)
            }"
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
    calls =
      module
      |> :meck.history()
      |> Enum.filter(fn
        {_, {^module, ^function, _}, _} -> true
        _ -> false
      end)

    if Enum.empty?(calls) do
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
    calls =
      module
      |> :meck.history()
      |> Enum.filter(fn
        {_, {^module, ^function, _}, _} -> true
        _ -> false
      end)
      |> Enum.map(fn {_, {_, _, args}, ret} ->
        {args, ret}
      end)

    unless Enum.empty?(calls) do
      formatted_calls =
        calls
        |> Enum.with_index(1)
        |> Enum.map(fn {{args, ret}, i} ->
          "#{i}. #{inspect(module)}.#{to_string(function)}(#{
            args |> Enum.map(&Kernel.inspect/1) |> Enum.join(", ")
          }) -> #{inspect(ret)}"
        end)

      message = """
      \n
      Unexpected call received, expected no calls:

        #{inspect(module)}.#{to_string(function)}

      Calls which were received:

      #{formatted_calls}
      """

      raise UnexpectedCall, message: message
    end
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
    ensure_mocked(real_module)

    real_functions = find_functions(real_module)
    fake_functions = find_functions(fake_module)

    Enum.each(fake_functions, fn {name, arity} ->
      is_real_function? = Enum.any?(real_functions, &match?({^name, ^arity}, &1))

      if is_real_function? do
        patch(real_module, name, Patch.Function.for_arity(arity, fn args ->
          apply(fake_module, name, args)
        end))
      end
    end)
  end

  @doc """
  Spies on the provided module

  Once a module has been spied on the calls to that module can be asserted / refuted without
  changing the behavior of the module.
  """
  @spec spy(module :: module()) :: :ok
  def spy(module) do
    ensure_mocked(module)
    :ok
  end

  @doc """
  Patches a function in a module

  The patched function will either always return the provided value or if a function is provided
  then the function will be called and its result returned.
  """
  @spec patch(module :: module(), function :: atom(), mock) :: mock when mock: fun()
  def patch(module, function, mock) when is_function(mock) do
    ensure_mocked(module)

    :meck.expect(module, function, mock)

    mock
  end

  @spec patch(module :: module(), function :: atom(), return_value) :: return_value
        when return_value: term()
  def patch(module, function, return_value) do
    ensure_mocked(module)

    module
    |> find_arities(function)
    |> Enum.each(fn arity ->
      :meck.expect(module, function, Patch.Function.for_arity(arity, fn _ -> return_value end))
    end)

    return_value
  end

  @spec real(module :: Module.t()) :: Module.t()
  def real(module) do
    :meck_util.original_name(module)
  end

  @doc """
  Remove any mocks or spies from the given module
  """
  @spec restore(module :: module()) :: :ok
  def restore(module) do
    if :meck.validate(module), do: :meck.unload(module)
  rescue
    _ in ErlangError ->
      :ok
  end

  ## Private

  @spec ensure_mocked(module :: module()) :: term()
  defp ensure_mocked(module) do
    :meck.validate(module)
  rescue
    _ in ErlangError ->
      :meck.new(module, [:passthrough])
  end

  @spec find_functions(module :: module()) :: Keyword.t(arity())
  defp find_functions(module) do
    Code.ensure_loaded(module)
    module.__info__(:functions)
  end

  @spec find_arities(module :: module(), function :: function()) :: [arity()]
  defp find_arities(module, function) do
    module
    |> find_functions()
    |> Keyword.get_values(function)
  end
end
