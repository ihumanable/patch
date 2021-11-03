defmodule Patch.Assertions do
  alias Patch.MissingCall
  alias Patch.Mock
  alias Patch.UnexpectedCall

  @doc """
  Asserts that the given module and function has been called with any arity.

  ```elixir
  patch(Example, :function, :patch)

  Patch.Assertions.assert_any_call(Example, :function)   # fails

  Example.function(1, 2, 3)

  Patch.Asertions.assert_any_call(Example, :function)   # passes
  ```

  There is a convenience delegate in the Developer Interface, `Patch.assert_any_call/2` which
  should be preferred over calling this function directly.
  """
  @spec assert_any_call(module :: module(), function :: atom()) :: nil
  def assert_any_call(module, function) do
    unless Mock.called?(module, function) do
      message = """
      \n
      Expected any call to the following function:

        #{inspect(module)}.#{to_string(function)}

      Calls which were received (matching calls are marked with *):

      #{format_calls_matching_any(module, function)}
      """

      raise MissingCall, message: message
    end
  end

  @doc """
  Given a call will assert that a matching call was observed by the patched function.

  The call can use the special sentinal `:_` as a wildcard match.

  ```elixir
  patch(Example, :function, :patch)

  Example.function(1, 2, 3)

  Patch.Assertions.assert_called(Example, :function, [1, 2, 3])   # passes
  Patch.Assertions.assert_called(Example, :function, [1, :_, 3])  # passes
  Patch.Assertions.assert_called(Example, :function, [4, 5, 6])   # fails
  Patch.Assertions.assert_called(Example, :function, [4, :_, 6])  # fails
  ```
  There is a convenience macro in the Developer Interface, `Patch.assert_called/1` which should be
  preferred over calling this function directly.
  """
  @spec assert_called(call :: Macro.t()) :: Macro.t()
  defmacro assert_called(call) do
    {module, function, patterns} = Macro.decompose_call(call)

    quote do
      unless Patch.Mock.called?(unquote(call)) do
        history = Patch.Mock.match_history(unquote(call))

        message = """
        \n
        Expected but did not receive the following call:

          #{inspect(unquote(module))}.#{to_string(unquote(function))}(#{Patch.Assertions.format_patterns(unquote(patterns))})

        Calls which were received (matching calls are marked with *):

        #{Patch.Assertions.format_history(unquote(module), history)}
        """

        raise MissingCall, message: message
      end

      {:ok, {unquote(function), arguments}} = Patch.Mock.latest_match(unquote(call))
      Patch.Macro.match(unquote(patterns), arguments)
    end
  end

  @doc """
  Given a call will assert that a matching call was observed exactly the number of times provided
  by the patched function.

  The call can use the special sentinal `:_` as a wildcard match.

  ```elixir
  patch(Example, :function, :patch)

  Example.function(1, 2, 3)

  Patch.Assertions.assert_called(Example, :function, [1, 2, 3], 1)   # passes
  Patch.Assertions.assert_called(Example, :function, [1, :_, 3], 1)  # passes

  Example.function(1, 2, 3)

  Patch.Assertions.assert_called(Example, :function, [1, 2, 3], 2)   # passes
  Patch.Assertions.assert_called(Example, :function, [1, :_, 3], 2)  # passes
  ```

  There is a convenience macro in the Developer Interface, `Patch.assert_called/2` which
  should be preferred over calling this function directly.
  """
  @spec assert_called(call :: Macro.t(), count :: non_neg_integer()) :: Macro.t()
  defmacro assert_called(call, count) do
    {module, function, patterns} = Macro.decompose_call(call)

    quote do
      call_count = Patch.Mock.call_count(unquote(call))
      unless call_count == unquote(count) do
        exception =
          if call_count < unquote(count) do
            MissingCall
          else
            UnexpectedCall
          end

        history = Patch.Mock.match_history(unquote(call))

        message = """
        \n
        Expected #{unquote(count)} of the following calls, but found #{call_count}:

          #{inspect(unquote(module))}.#{to_string(unquote(function))}(#{Patch.Assertions.format_patterns(unquote(patterns))})

        Calls which were received (matching calls are marked with *):

        #{Patch.Assertions.format_history(unquote(module), history)}
        """

        raise exception, message
      end

      {:ok, {unquote(function), arguments}} = Patch.Mock.latest_match(unquote(call))
      Patch.Macro.match(unquote(patterns), arguments)
    end
  end

  @doc """
  Given a call will assert that a matching call was observed exactly once by the patched function.

  The call can use the special sentinal `:_` as a wildcard match.

  ```elixir
  patch(Example, :function, :patch)

  Example.function(1, 2, 3)

  Patch.Assertions.assert_called_once(Example, :function, [1, 2, 3])   # passes
  Patch.Assertions.assert_called_once(Example, :function, [1, :_, 3])  # passes

  Example.function(1, 2, 3)

  Patch.Assertions.assert_called_once(Example, :function, [1, 2, 3])   # fails
  Patch.Assertions.assert_called_once(Example, :function, [1, :_, 3])  # fails
  ```

  There is a convenience macro in the Developer Interface, `Patch.assert_called_once/1` which
  should be preferred over calling this function directly.
  """
  @spec assert_called_once(call :: Macro.t()) :: Macro.t()
  defmacro assert_called_once(call) do
    {module, function, patterns} = Macro.decompose_call(call)

    quote do
      call_count = Patch.Mock.call_count(unquote(call))

      unless call_count == 1 do
        exception =
          if call_count == 0 do
            MissingCall
          else
            UnexpectedCall
          end

        history = Patch.Mock.match_history(unquote(call))

        message = """
        \n
        Expected the following call to occur exactly once, but call occurred #{call_count} times:

          #{inspect(unquote(module))}.#{to_string(unquote(function))}(#{Patch.Assertions.format_patterns(unquote(patterns))})

        Calls which were received (matching calls are marked with *):

        #{Patch.Assertions.format_history(unquote(module), history)}
        """

        raise exception, message
      end

      {:ok, {unquote(function), arguments}} = Patch.Mock.latest_match(unquote(call))
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

  There is a convenience delegate in the Developer Interface, `Patch.refute_any_call/2` which
  should be preferred over calling this function directly.
  """
  @spec refute_any_call(module :: module(), function :: atom()) :: nil
  def refute_any_call(module, function) do
    if Mock.called?(module, function) do
      message = """
      \n
      Unexpected call received, expected no calls:

        #{inspect(module)}.#{to_string(function)}

      Calls which were received (matching calls are marked with *):

      #{format_calls_matching_any(module, function)}
      """

      raise UnexpectedCall, message: message
    end
  end

  @doc """
  Given a call will refute that a matching call was observed by the patched function.

  The call can use the special sentinal `:_` as a wildcard match.

  ```elixir
  patch(Example, :function, :patch)

  Example.function(1, 2, 3)

  Patch.Assertions.refute_called(Example, :function, [4, 5, 6])   # passes
  Patch.Assertions.refute_called(Example, :function, [4, :_, 6])  # passes
  Patch.Assertions.refute_called(Example, :function, [1, 2, 3])   # fails
  Patch.Assertions.refute_called(Example, :function, [1, :_, 3])  # passes
  ```

  There is a convenience macro in the Developer Interface, `Patch.refute_called/1` which should be
  preferred over calling this function directly.
  """
  @spec refute_called(call :: Macro.t()) :: Macro.t()
  defmacro refute_called(call) do
    {module, function, patterns} = Macro.decompose_call(call)

    quote do
      if Patch.Mock.called?(unquote(call)) do
        history = Patch.Mock.match_history(unquote(call))

        message = """
        \n
        Unexpected call received:

          #{inspect(unquote(module))}.#{to_string(unquote(function))}(#{Patch.Assertions.format_patterns(unquote(patterns))})

        Calls which were received (matching calls are marked with *):

        #{Patch.Assertions.format_history(unquote(module), history)}
        """

        raise UnexpectedCall, message: message
      end
    end
  end

  @doc """
  Given a call will refute that a matching call was observed exactly the number of times provided
  by the patched function.

  The call can use the special sentinal `:_` as a wildcard match.

  ```elixir
  patch(Example, :function, :patch)

  Example.function(1, 2, 3)

  Patch.Assertions.refute_called(Example, :function, [1, 2, 3], 2)   # passes
  Patch.Assertions.refute_called(Example, :function, [1, :_, 3], 2)  # passes

  Example.function(1, 2, 3)

  Patch.Assertions.refute_called(Example, :function, [1, 2, 3], 1)   # passes
  Patch.Assertions.refute_called(Example, :function, [1, :_, 3], 1)  # passes
  ```

  There is a convenience macro in the Developer Interface, `Patch.refute_called/2` which
  should be preferred over calling this function directly.
  """
  @spec refute_called(call :: Macro.t(), count :: non_neg_integer()) :: Macro.t()
  defmacro refute_called(call, count) do
    {module, function, patterns} = Macro.decompose_call(call)

    quote do
      call_count = Patch.Mock.call_count(unquote(call))

      if call_count == unquote(count) do
        history = Patch.Mock.match_history(unquote(call))

        message = """
        \n
        Expected any count except #{unquote(count)} of the following calls, but found #{call_count}:

          #{inspect(unquote(module))}.#{to_string(unquote(function))}(#{Patch.Assertions.format_patterns(unquote(patterns))})

        Calls which were received (matching calls are marked with *):

        #{Patch.Assertions.format_history(unquote(module), history)}
        """

        raise UnexpectedCall, message
      end
    end
  end

  @doc """
  Given a call will refute that a matching call was observed exactly once by the patched function.

  The call can use the special sentinal `:_` as a wildcard match.

  ```elixir
  patch(Example, :function, :patch)

  Example.function(1, 2, 3)

  Patch.Assertions.refute_called_once(Example, :function, [1, 2, 3])   # fails
  Patch.Assertions.refute_called_once(Example, :function, [1, :_, 3])  # fails

  Example.function(1, 2, 3)

  Patch.Assertions.refute_called_once(Example, :function, [1, 2, 3])   # passes
  Patch.Assertions.refute_called_once(Example, :function, [1, :_, 3])  # passes
  ```

  There is a convenience macro in the Developer Interface, `Patch.refute_called_once/1` which
  should be preferred over calling this function directly.
  """
  @spec refute_called_once(call :: Macro.t()) :: Macro.t()
  defmacro refute_called_once(call) do
    {module, function, patterns} = Macro.decompose_call(call)

    quote do
      call_count = Patch.Mock.call_count(unquote(call))

      if call_count == 1 do
        history = Patch.Mock.match_history(unquote(call))

        message = """
        \n
        Expected the following call to occur any number of times but once, but it occurred once:

          #{inspect(unquote(module))}.#{to_string(unquote(function))}(#{Patch.Assertions.format_patterns(unquote(patterns))})

        Calls which were received (matching calls are marked with *):

        #{Patch.Assertions.format_history(unquote(module), history)}
        """

        raise UnexpectedCall, message
      end
    end
  end

  @doc """
  Prints a list of patterns AST as an argument list.
  """
  @spec format_patterns(patterns :: [term()]) :: String.t()
  defmacro format_patterns(patterns) do
    patterns
    |> Macro.to_string()
    |> String.slice(1..-2)
  end

  @spec format_history(module :: Module.t(), calls :: [{atom(), [term()]}]) :: String.t()
  def format_history(module, calls) do
    calls
    |> Enum.reverse()
    |> Enum.with_index(1)
    |> Enum.map(fn {{matches, {function, arguments}}, i} ->
      marker =
        if matches do
          "* "
        else
          "  "
        end

      "#{marker}#{i}. #{inspect(module)}.#{function}(#{format_arguments(arguments)})"
    end)
    |> case do
      [] ->
        "  [No Calls Received]"
      calls ->
        Enum.join(calls, "\n")
    end
  end

  ## Private

  @spec format_arguments(arguments :: [term()]) :: String.t()
  defp format_arguments(arguments) do
    arguments
    |> Enum.map(&Kernel.inspect/1)
    |> Enum.join(", ")
  end

  @spec format_calls_matching_any(module :: module(), expected_function :: atom()) :: String.t()
  defp format_calls_matching_any(module, expected_function) do
    module
    |> Patch.history()
    |> Enum.with_index(1)
    |> Enum.map(fn {{actual_function, arguments}, i} ->
      marker =
        if expected_function == actual_function do
          "* "
        else
          "  "
        end

      "#{marker}#{i}. #{inspect(module)}.#{actual_function}(#{format_arguments(arguments)})"
    end)
    |> case do
      [] ->
        "  [No Calls Received]"
      calls ->
        Enum.join(calls, "\n")
    end
  end
end
