defmodule Patch.Mock.Code.Transforms.Rename do
  alias Patch.Mock.Code

  @generated [generated: true]

  @doc """
  Transforms the provided forms to rename the module to the provided module
  name.
  """
  @spec transform(abstract_forms :: [Code.form()], module :: module) :: [Code.form()]
  def transform(abstract_forms, module) do
    Enum.map(abstract_forms, fn
      {:attribute, _, :module, _} ->
        {:attribute, @generated, :module, module}

      other ->
        other
    end)
  end
end
