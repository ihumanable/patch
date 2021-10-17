defmodule Patch.Mock.Code.Queries.Exports do
  alias Patch.Mock.Code

  @doc """
  Queries the provided forms for the exported functions.
  """
  @spec query(abstract_forms :: [Code.form()]) :: Code.exports()
  def query(abstract_forms) do
    abstract_forms
    |> Enum.filter(&match?({:attribute, _, :export, _}, &1))
    |> Enum.reduce([], fn {_, _, _, exports}, acc ->
      Keyword.merge(acc, exports)
    end)
  end
end
