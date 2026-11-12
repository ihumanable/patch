defmodule Patch.Mock.Code.Transforms.Rename do
  alias Patch.Mock.Code

  @doc """
  Transforms the provided forms to rename the module to the provided module
  name.
  """
  @spec transform(abstract_forms :: [Code.form()], module :: module) :: [Code.form()]
  def transform(abstract_forms, module) do
    Enum.map(abstract_forms, fn
      {:attribute, anno, :module, _} ->
        {:attribute, :erl_anno.set_generated(true, anno), :module, module}

      other ->
        other
    end)
  end
end
