defmodule Patch.Mock.Code.Transforms.Clean do
  @moduledoc """
  Cleans abstract form to prepare it for subsequent generation.

  The following forms are retained:
    - module attribute
    - exports
    - no_auto_import compiler options (This is needed to prevent R14 shadow import warnings)
    - functions
  """

  alias Patch.Mock.Code

  @spec transform(abstract_forms :: [Code.form()]) :: [Code.form()]
  def transform(abstract_forms) do
    Enum.filter(abstract_forms, fn
      {:attribute, _, :module, _} ->
        true

      {:attribute, _, :export, _} ->
        true

      {:attribute, _, :compile, [:no_auto_import]} ->
        true

      {:attribute, _, :compile, [:no_auto_import, _]} ->
        true

      {:function, _, _, _, _} ->
        true

      _ ->
        false
    end)
  end
end
