defmodule Patch.Mock.Code.Queries.Functions do
  alias Patch.Mock.Code

  @doc """
  Queries the provided forms for all defined functions.
  """
  @spec query(abstract_forms :: [Code.form()]) :: Code.exports()
  def query(abstract_forms) do
    abstract_forms
    |> Enum.filter(&match?({:function, _, _, _, _}, &1))
    |> Enum.reduce([], fn {:function, _, name, arity, _}, acc ->
      [{name, arity} | acc]
    end)
  end
end
