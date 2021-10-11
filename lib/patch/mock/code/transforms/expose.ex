defmodule Patch.Mock.Code.Transforms.Expose do
  alias Patch.Mock.Code
  alias Patch.Mock.Code.Query
  alias Patch.Mock.Code.Transform

  @generated [generated: true]

  @doc """
  Transforms the provided forms to export none, some, or all of the private
  functions.
  """
  @spec transform(abstract_forms :: [Code.form()], exposes :: Transform.exposes()) :: [
          Code.form()
        ]
  def transform(abstract_forms, :none) do
    abstract_forms
  end

  def transform(abstract_forms, :all) do
    exports = Query.functions(abstract_forms)
    replace_exports(abstract_forms, exports)
  end

  def transform(abstract_forms, exposes) do
    exports = exposes ++ Query.exports(abstract_forms)
    replace_exports(abstract_forms, exports)
  end

  ## Private

  @spec replace_exports(abstract_forms :: [Code.form()], exports :: Code.exports()) :: [
          Code.form()
        ]
  defp replace_exports(abstract_forms, exports) do
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
