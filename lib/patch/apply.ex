defmodule Patch.Apply do
  @moduledoc """
  Utility module to assist with applying functions.
  """

  @doc """
  Safe application of an anonymous function.

  This is just like `apply/2` but if the the anonymous function is unable to
  handle the call (raising either `BadArityError` or `FunctionClauseError`) then
  the `:error` atom is returned.

  If the function evaluates successfully its reply is returned wrapped in an
  `{:ok, result}` tuple.
  """
  @spec safe(function :: function(), arguments :: [term()]) :: {:ok, term()} | :error
  def safe(function, arguments) do
    try do
      result = apply(function, arguments)

      {:ok, result}
    rescue
      e in [BadArityError, FunctionClauseError] ->
        if direct_exception?(function, e) do
          :error
        else
          reraise e, __STACKTRACE__
        end
    end
  end

  ## Private

  @spec direct_exception?(function :: function(), error :: Exception.t()) :: boolean()
  defp direct_exception?(function, %BadArityError{} = error) do
    function == error.function
  end

  defp direct_exception?(function, %FunctionClauseError{} = error) do
    info = Function.info(function)
    info[:arity] == error.arity and info[:name] == error.function
  end
end
