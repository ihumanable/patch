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
    quote bind_quoted: [call: call] do
      unless Patch.Mock.called?(call) do
        message = """
        \n
        Expected but did not receive the following call:

          #{inspect(module)}.#{to_string(function)}(#{format_patterns(patterns)})

        Calls which were received (matching calls are marked with *):

        #{format_calls_matching(module, function, patterns)}
        """

        raise MissingCall, message: message
      end
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
  @spec assert_called(module :: module(), function :: atom(), arguments :: [term()], count :: non_neg_integer()) :: nil
  def assert_called(module, function, arguments, count) do
    call_count = Patch.Mock.call_count(module, function, arguments)

    unless call_count == count do
      exception =
        if call_count < count do
          MissingCall
        else
          UnexpectedCall
        end

      message = """
      \n
      Expected #{count} of the following calls, but found #{call_count}:

        #{inspect(module)}.#{to_string(function)}(#{format_arguments(arguments)})

      Calls which were received (matching calls are marked with *):

      #{format_calls_matching(module, function, arguments)}
      """

      raise exception, message
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
  @spec assert_called_once(module :: module(), function :: atom(), arguments :: [term()]) :: nil
  def assert_called_once(module, function, arguments) do
    call_count = Patch.Mock.call_count(module, function, arguments)

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

        #{inspect(module)}.#{to_string(function)}(#{format_arguments(arguments)})

      Calls which were received (matching calls are marked with *):

      #{format_calls_matching(module, function, arguments)}
      """

      raise exception, message
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
  @spec refute_called(module :: module(), function :: atom(), arguments :: [term()]) :: nil
  def refute_called(module, function, arguments) do
    if Patch.Mock.called?(module, function, arguments) do
      message = """
      \n
      Unexpected call received:

        #{inspect(module)}.#{to_string(function)}(#{format_arguments(arguments)})

      Calls which were received (matching calls are marked with *):

      #{format_calls_matching(module, function, arguments)}
      """

      raise UnexpectedCall, message: message
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
  @spec refute_called(module :: module(), function :: atom(), arguments :: [term()], count :: non_neg_integer()) :: nil
  def refute_called(module, function, arguments, count) do
    call_count = Patch.Mock.call_count(module, function, arguments)

    if call_count == count do
      message = """
      \n
      Expected any count except #{count} of the following calls, but found #{count}:

        #{inspect(module)}.#{to_string(function)}(#{format_arguments(arguments)})

      Calls which were received (matching calls are marked with *):

      #{format_calls_matching(module, function, arguments)}
      """

      raise UnexpectedCall, message
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
  @spec refute_called_once(module :: module(), function :: atom(), arguments :: [term()]) :: nil
  def refute_called_once(module, function, arguments) do
    call_count = Patch.Mock.call_count(module, function, arguments)

    if call_count == 1 do
      message = """
      \n
      Expected the following call to occur any number of times but once, but it occurred once:

        #{inspect(module)}.#{to_string(function)}(#{format_arguments(arguments)})

      Calls which were received (matching calls are marked with *):

      #{format_calls_matching(module, function, arguments)}
      """

      raise UnexpectedCall, message
    end
  end

  ## Private

  @spec format_arguments(arguments :: [term()]) :: String.t()
  defp format_arguments(arguments) do
    arguments
    |> Enum.map(&Kernel.inspect/1)
    |> Enum.join(", ")
  end

  @spec format_patterns(patterns :: [term()]) :: String.t()
  defp format_patterns(patterns) do
    Macro.to_string(patterns)
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

  @spec format_calls_matching(module :: module(), expected_function :: atom(), expected_arguments :: [term()]) :: String.t()
  defp format_calls_matching(module, expected_function, expected_arguments) do
    module
    |> Patch.history()
    |> Enum.with_index(1)
    |> Enum.map(fn {{actual_function, actual_arguments}, i} ->
      marker =
        if expected_function == actual_function and Mock.arguments_compatible?(expected_arguments, actual_arguments) do
          "* "
        else
          "  "
        end

      "#{marker}#{i}. #{inspect(module)}.#{actual_function}(#{format_arguments(actual_arguments)})"
    end)
    |> case do
      [] ->
        "  [No Calls Received]"
      calls ->
        Enum.join(calls, "\n")
    end
  end

end
