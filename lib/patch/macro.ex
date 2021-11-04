defmodule Patch.Macro do
  @doc """
  Utility function that acts like `inspect/1` but prints out the Macro as code.
  """
  @spec debug(ast :: Macro.t()) :: Macro.t()
  def debug(ast) do
    ast
    |> Macro.to_string()
    |> IO.puts()

    ast
  end

  @doc """
  Performs an non-hygienic match.

  If the match succeeds true is returned, otherwise a MatchError is raised.

  Since the match is non-hygienic pins can be used from the user-scope and binds will effect
  user-scope.
  """
  @spec match(pattern :: Macro.t(), expression :: Macro.t()) :: Macro.t()
  defmacro match(pattern, expression) do
    user_pattern = user_variables(pattern)
    pattern_expression = pattern_expression(pattern)
    variables = variables(pattern)

    quote generated: true do
      unquote(pattern_expression) =
        case unquote(expression) do
          unquote(user_pattern) ->
            _ = unquote(variables)
            unquote(expression)

          _ ->
            raise MatchError, term: unquote(expression)
        end

      _ = unquote(variables)
      true
    end
  end

  @doc """
  Performs a match, return true if match matches, false otherwise.
  """
  @spec match?(pattern :: Macro.t(), expression :: Macro.t()) :: Macro.t()
  defmacro match?(pattern, expression) do
    quote generated: true do
      try do
        Patch.Macro.match(unquote(pattern), unquote(expression))
        true
      rescue
        MatchError ->
          false
      end
    end
  end

  ## Private

  defp pattern_expression(pattern) do
    Macro.prewalk(pattern, fn
      {:^, _, [{name, meta, _}]}  ->
        {name, meta, nil}

      {:_, _, _} ->
        unique_variable()

      node ->
        node
    end)
  end

  defp unique_variable do
    {:"_ignore#{:erlang.unique_integer([:positive])}", [generated: true], nil}
  end

  defp user_variables(pattern) do
    Macro.prewalk(pattern, fn
      {name, meta, context} when is_atom(name) and is_atom(context) ->
        {name, meta, nil}

      node ->
        node
    end)
  end

  defp variables(pattern) do
    pattern
    |> Macro.prewalk([], fn
      {:_, _, _} = node, acc ->
        {node, acc}

      {name, meta, context} = node, acc when is_atom(name) and is_atom(context) ->
        ignored? =
          name
          |> Atom.to_string()
          |> String.starts_with?("_")

        if ignored? do
          {node, acc}
        else
          {node, [{name, meta, nil} | acc]}
        end

      node, acc ->
        {node, acc}
    end)
    |> elem(1)
  end
end
