defmodule Patch.Mock.Code.Transforms.Clean do
  @moduledoc """
  Cleans abstract form to prepare it for subsequent generation.

  Everything except for the module attribute, exports, and functions are removed.
  """

  alias Patch.Mock.Code

  @spec transform(abstract_forms :: [Code.form()]) :: [Code.form()]
  def transform(abstract_forms) do
    Enum.filter(abstract_forms, fn
      {:attribute, _, :module, _} ->
        true

      {:attribute, _, :export, _} ->
        true

      {:function, _, _, _, _} ->
        true

      _ ->
        false
    end)
  end
end
