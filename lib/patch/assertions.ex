defmodule Patch.Assertions do
  alias Patch.MissingCall
  alias Patch.Mock
  alias Patch.Mock.History
  alias Patch.UnexpectedCall

  @doc """
  Asserts that the given module and function has been called with any arity.

  ```elixir
  patch(Example, :function, :patch)

  Patch.Assertions.assert_any_call(Example, :function)   # fails

  Example.function(1, 2, 3)

  Patch.Asertions.assert_any_call(Example, :function)   # passes
  ```

  There are convenience delegates in the Developer Interface, `Patch.assert_any_call/1` and
  `Patch.assert_any_call/2` which should be preferred over calling this function directly.
  """
  @spec assert_any_call(module :: module(), function :: atom()) :: nil
  def assert_any_call(module, function) do
    history =
      module
      |> Mock.history()
      |> History.Tagged.for_function(function)

    unless History.Tagged.any?(history) do
      message = """
      \n
      Expected any call to the following function:

        #{inspect(module)}.#{to_string(function)}

      Calls which were received (matching calls are marked with *):

      #{History.Tagged.format(history, module)}
      """

      raise MissingCall, message: message
    end
  end

  @doc """
  Given a call will assert that a matching call was observed by the patched function.

  This macro fully supports patterns and will perform non-hygienic binding similar to ExUnit's
  `assert_receive/3` and `assert_received/2`.

  ```elixir
  patch(Example, :function, :patch)

  Example.function(1, 2, 3)

  Patch.Assertions.assert_called(Example, :function, [1, 2, 3])   # passes
  Patch.Assertions.assert_called(Example, :function, [1, _, 3])   # passes
  Patch.Assertions.assert_called(Example, :function, [4, 5, 6])   # fails
  Patch.Assertions.assert_called(Example, :function, [4, _, 6])   # fails
  ```

  There is a convenience macro in the Developer Interface, `Patch.assert_called/1` which should be
  preferred over calling this macro directly.
  """
  @spec assert_called(call :: Macro.t()) :: Macro.t()
  defmacro assert_called(call) do
    {module, function, patterns} = Macro.decompose_call(call)

    quote do
      history =
        unquote(module)
        |> Patch.Mock.history()
        |> Patch.Mock.History.Tagged.for_call(unquote(call))

      unless Patch.Mock.History.Tagged.any?(history) do
        message = """
        \n
        Expected but did not receive the following call:

          #{inspect(unquote(module))}.#{to_string(unquote(function))}(#{Patch.Assertions.format_patterns(unquote(patterns))})

        Calls which were received (matching calls are marked with *):

        #{Patch.Mock.History.Tagged.format(history, unquote(module))}
        """

        raise MissingCall, message: message
      end

      {:ok, {unquote(function), arguments}} = Patch.Mock.History.Tagged.first(history)
      Patch.Macro.match(unquote(patterns), arguments)
    end
  end

  @doc """
  Given a call will assert that a matching call was observed exactly the number of times provided
  by the patched function.

  This macro fully supports patterns and will perform non-hygienic binding similar to ExUnit's
  `assert_receive/3` and `assert_received/2`.  The value bound will be the from the latest call.

  ```elixir
  patch(Example, :function, :patch)

  Example.function(1, 2, 3)

  Patch.Assertions.assert_called(Example, :function, [1, 2, 3], 1)   # passes
  Patch.Assertions.assert_called(Example, :function, [1, _, 3], 1)  # passes

  Example.function(1, 2, 3)

  Patch.Assertions.assert_called(Example, :function, [1, 2, 3], 2)   # passes
  Patch.Assertions.assert_called(Example, :function, [1, _, 3], 2)  # passes
  ```

  There is a convenience macro in the Developer Interface, `Patch.assert_called/2` which
  should be preferred over calling this macro directly.
  """
  @spec assert_called(call :: Macro.t(), count :: non_neg_integer()) :: Macro.t()
  defmacro assert_called(call, count) do
    {module, function, patterns} = Macro.decompose_call(call)

    quote do
      history =
        unquote(module)
        |> Patch.Mock.history()
        |> Patch.Mock.History.Tagged.for_call(unquote(call))

      call_count = Patch.Mock.History.Tagged.count(history)

      unless call_count == unquote(count) do
        exception =
          if call_count < unquote(count) do
            MissingCall
          else
            UnexpectedCall
          end

        message = """
        \n
        Expected #{unquote(count)} of the following calls, but found #{call_count}:

          #{inspect(unquote(module))}.#{to_string(unquote(function))}(#{Patch.Assertions.format_patterns(unquote(patterns))})

        Calls which were received (matching calls are marked with *):

        #{Patch.Mock.History.Tagged.format(history, unquote(module))}
        """

        raise exception, message
      end

      {:ok, {unquote(function), arguments}} = Patch.Mock.History.Tagged.first(history)
      Patch.Macro.match(unquote(patterns), arguments)
    end
  end

  @doc """
  Given a call will assert that a matching call was observed exactly once by the patched function.

  This macro fully supports patterns and will perform non-hygienic binding similar to ExUnit's
  `assert_receive/3` and `assert_received/2`.

  ```elixir
  patch(Example, :function, :patch)

  Example.function(1, 2, 3)

  Patch.Assertions.assert_called_once(Example, :function, [1, 2, 3])   # passes
  Patch.Assertions.assert_called_once(Example, :function, [1, _, 3])  # passes

  Example.function(1, 2, 3)

  Patch.Assertions.assert_called_once(Example, :function, [1, 2, 3])   # fails
  Patch.Assertions.assert_called_once(Example, :function, [1, _, 3])  # fails
  ```

  There is a convenience macro in the Developer Interface, `Patch.assert_called_once/1` which
  should be preferred over calling this macro directly.
  """
  @spec assert_called_once(call :: Macro.t()) :: Macro.t()
  defmacro assert_called_once(call) do
    {module, function, patterns} = Macro.decompose_call(call)

    quote do
      history =
        unquote(module)
        |> Patch.Mock.history()
        |> Patch.Mock.History.Tagged.for_call(unquote(call))

      call_count = Patch.Mock.History.Tagged.count(history)

      unless call_count == 1 do
        exception =
          if call_count == 0 do
            MissingCall
          else
            UnexpectedCall
          end

        message = """
        \n
        Expected the following call to occur exactly once, but call occurred #{call_count} times:

          #{inspect(unquote(module))}.#{to_string(unquote(function))}(#{Patch.Assertions.format_patterns(unquote(patterns))})

        Calls which were received (matching calls are marked with *):

        #{Patch.Mock.History.Tagged.format(history, unquote(module))}
        """

        raise exception, message
      end

      {:ok, {unquote(function), arguments}} = Patch.Mock.History.Tagged.first(history)
      Patch.Macro.match(unquote(patterns), arguments)
    end
  end

  @doc """
  Refutes that the given module and function has been called with any arity.

  ```elixir
  patch(Example, :function, :patch)

  Patch.Assertions.refute_any_call(Example, :function)   # passes

  Example.function(1, 2, 3)

  Patch.Assertions.refute_any_call(Example, :function)   # fails
  ```

  There are convenience delegates in the Developer Interface, `Patch.refute_any_call/1` and
  `Patch.refute_any_call/2` which should be preferred over calling this function directly.
  """
  @spec refute_any_call(module :: module(), function :: atom()) :: nil
  def refute_any_call(module, function) do
    history =
      module
      |> Mock.history()
      |> History.Tagged.for_function(function)

    if History.Tagged.any?(history) do
      message = """
      \n
      Unexpected call received, expected no calls:

        #{inspect(module)}.#{to_string(function)}

      Calls which were received (matching calls are marked with *):

      #{History.Tagged.format(history, module)}
      """

      raise UnexpectedCall, message: message
    end
  end

  @doc """
  Given a call will refute that a matching call was observed by the patched function.

  This macro fully supports patterns.

  ```elixir
  patch(Example, :function, :patch)

  Example.function(1, 2, 3)

  Patch.Assertions.refute_called(Example, :function, [4, 5, 6])   # passes
  Patch.Assertions.refute_called(Example, :function, [4, _, 6])  # passes
  Patch.Assertions.refute_called(Example, :function, [1, 2, 3])   # fails
  Patch.Assertions.refute_called(Example, :function, [1, _, 3])  # passes
  ```

  There is a convenience macro in the Developer Interface, `Patch.refute_called/1` which should be
  preferred over calling this macro directly.
  """
  @spec refute_called(call :: Macro.t()) :: Macro.t()
  defmacro refute_called(call) do
    {module, function, patterns} = Macro.decompose_call(call)

    quote do
      history =
        unquote(module)
        |> Patch.Mock.history()
        |> Patch.Mock.History.Tagged.for_call(unquote(call))

      if Patch.Mock.History.Tagged.any?(history) do
        message = """
        \n
        Unexpected call received:

          #{inspect(unquote(module))}.#{to_string(unquote(function))}(#{Patch.Assertions.format_patterns(unquote(patterns))})

        Calls which were received (matching calls are marked with *):

        #{Patch.Mock.History.Tagged.format(history, unquote(module))}
        """

        raise UnexpectedCall, message: message
      end
    end
  end

  @doc """
  Given a call will refute that a matching call was observed exactly the number of times provided
  by the patched function.

  This macro fully supports patterns.

  ```elixir
  patch(Example, :function, :patch)

  Example.function(1, 2, 3)

  Patch.Assertions.refute_called(Example, :function, [1, 2, 3], 2)   # passes
  Patch.Assertions.refute_called(Example, :function, [1, _, 3], 2)  # passes

  Example.function(1, 2, 3)

  Patch.Assertions.refute_called(Example, :function, [1, 2, 3], 1)   # passes
  Patch.Assertions.refute_called(Example, :function, [1, _, 3], 1)  # passes
  ```

  There is a convenience macro in the Developer Interface, `Patch.refute_called/2` which
  should be preferred over calling this macro directly.
  """
  @spec refute_called(call :: Macro.t(), count :: non_neg_integer()) :: Macro.t()
  defmacro refute_called(call, count) do
    {module, function, patterns} = Macro.decompose_call(call)

    quote do
      history =
        unquote(module)
        |> Patch.Mock.history()
        |> Patch.Mock.History.Tagged.for_call(unquote(call))

      call_count = Patch.Mock.History.Tagged.count(history)

      if call_count == unquote(count) do
        message = """
        \n
        Expected any count except #{unquote(count)} of the following calls, but found #{call_count}:

          #{inspect(unquote(module))}.#{to_string(unquote(function))}(#{Patch.Assertions.format_patterns(unquote(patterns))})

        Calls which were received (matching calls are marked with *):

        #{Patch.Mock.History.Tagged.format(history, unquote(module))}
        """

        raise UnexpectedCall, message
      end
    end
  end

  @doc """
  Given a call will refute that a matching call was observed exactly once by the patched function.

  This macro fully supports patterns.

  ```elixir
  patch(Example, :function, :patch)

  Example.function(1, 2, 3)

  Patch.Assertions.refute_called_once(Example, :function, [1, 2, 3])   # fails
  Patch.Assertions.refute_called_once(Example, :function, [1, _, 3])  # fails

  Example.function(1, 2, 3)

  Patch.Assertions.refute_called_once(Example, :function, [1, 2, 3])   # passes
  Patch.Assertions.refute_called_once(Example, :function, [1, _, 3])  # passes
  ```

  There is a convenience macro in the Developer Interface, `Patch.refute_called_once/1` which
  should be preferred over calling this macro directly.
  """
  @spec refute_called_once(call :: Macro.t()) :: Macro.t()
  defmacro refute_called_once(call) do
    {module, function, patterns} = Macro.decompose_call(call)

    quote do
      history =
        unquote(module)
        |> Patch.Mock.history()
        |> Patch.Mock.History.Tagged.for_call(unquote(call))

      call_count = Patch.Mock.History.Tagged.count(history)

      if call_count == 1 do
        message = """
        \n
        Expected the following call to occur any number of times but once, but it occurred once:

          #{inspect(unquote(module))}.#{to_string(unquote(function))}(#{Patch.Assertions.format_patterns(unquote(patterns))})

        Calls which were received (matching calls are marked with *):

        #{Patch.Mock.History.Tagged.format(history, unquote(module))}
        """

        raise UnexpectedCall, message
      end
    end
  end

  @doc """
  Formats the AST for a list of patterns AST as they would appear in an argument list.
  """
  @spec format_patterns(patterns :: [term()]) :: String.t()
  defmacro format_patterns(patterns) do
    patterns
    |> Macro.to_string()
    |> String.slice(1..-2)
  end

end
