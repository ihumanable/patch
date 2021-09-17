defmodule Patch.Reflection do
  @spec find_functions(module :: module()) :: Keyword.t(arity())
  def find_functions(module) do
    Code.ensure_loaded(module)

    cond do
      function_exported?(module, :__info__, 1) ->
        module.__info__(:functions)

      function_exported?(module, :module_info, 1) ->
        module.module_info(:exports)

      true ->
        []
    end
  end

  @spec find_arities(module :: module(), function :: function()) :: [arity()]
  def find_arities(module, function) do
    module
    |> find_functions()
    |> Keyword.get_values(function)
  end
end
