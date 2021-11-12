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
    abstract_forms
    |> Enum.reduce([], fn
      {:attribute, _, :module, _} = form, acc ->
        [form | acc]

      {:attribute, _, :export, _} = form, acc ->
        [form | acc]

      {:attribute, anno, :compile, options}, acc ->
        case filter_compile_options(options) do
          [] ->
            acc

          options ->
            form = {:attribute, anno, :compile, options}
            [form | acc]
        end

      {:function, _, _, _, _} = form, acc ->
        [form | acc]

      _, acc ->
        acc
    end)
    |> Enum.reverse()
  end

  ## Private Functions

  @spec filter_compile_options(option :: term()) :: term()
  defp filter_compile_options(:no_auto_import) do
    :no_auto_import
  end

  defp filter_compile_options({:no_auto_import, _} = option)  do
    option
  end

  @spec filter_compile_options(options :: [term()]) :: [term()]
  defp filter_compile_options(options) when is_list(options) do
    Enum.filter(options, fn
      :no_auto_import ->
        true

      {:no_auto_import, _} ->
        true

      _ ->
        false
    end)
  end

  defp filter_compile_options(_) do
    []
  end
end
