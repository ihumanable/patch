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
      BadArityError ->
        :error

      FunctionClauseError ->
        :error
    end
  end
end
