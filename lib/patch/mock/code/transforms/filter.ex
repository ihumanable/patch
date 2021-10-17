defmodule Patch.Mock.Code.Transforms.Filter do
  @moduledoc """
  Filters the functions and specifications in a module to the exports provided.
  """

  alias Patch.Mock.Code

  @spec transform(abstract_forms :: [Code.form()], exports :: Code.exports()) :: [Code.form()]
  def transform(abstract_forms, exports) do
    Enum.filter(abstract_forms, fn
      {:attribute, _, :spec, {name_arity, _}} ->
        name_arity in exports

      {:function, _, name, arity, _} ->
        {name, arity} in exports

      _ ->
        true
    end)
  end
end
