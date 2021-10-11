defmodule Patch.Mock.Code.Transforms.Clean do
  @moduledoc """
  Cleans abstract form to prepare it for subsequent generation.

  Everything except for the module attribute, exports, and functions are removed
  """

  def transform(abstract_form) do
    Enum.filter(abstract_form, fn
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
