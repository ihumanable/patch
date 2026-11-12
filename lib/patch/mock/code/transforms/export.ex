defmodule Patch.Mock.Code.Transforms.Export do
  alias Patch.Mock.Code

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
      {:attribute, anno, :export, _}, {acc, false} ->
        {[{:attribute, :erl_anno.set_generated(true, anno), :export, exports} | acc], true}

      {:attribute, _, :export, _}, {acc, true} ->
        {acc, true}

      other, {acc, exported?} ->
        {[other | acc], exported?}
    end)
    |> elem(0)
    |> Enum.reverse()
  end
end
