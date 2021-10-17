defmodule Patch.Mock.Code.Transforms.Export do
  alias Patch.Mock.Code

  @generated [generated: true]

  @doc """
  Transforms the provided forms to export the given list of functions.
  """
  @spec transform(
          abstract_forms :: [Code.form()],
          exports :: Code.exports()
        ) :: [Code.form()]
  def transform(abstract_forms, exports) do
    abstract_forms
    |> Enum.reduce({[], false}, fn
      {:attribute, _, :export, _}, {acc, false} ->
        {[{:attribute, @generated, :export, exports} | acc], true}

      {:attribute, _, :export, _}, {acc, true} ->
        {acc, true}

      other, {acc, exported?} ->
        {[other | acc], exported?}
    end)
    |> elem(0)
    |> Enum.reverse()
  end
end
