defmodule Patch.Mock.Code.Query do
  @moduledoc """
  This module provides the ability to query abstract forms.

  This module delegates queries to purpose specific Queries modules, see those modules for
  additional details on how specific queries work.

  - `Patch.Mock.Code.Queries.Exports` for how exports are queried
  - `Patch.Mock.Code.Queries.Functions` for how functions are queried
  """

  alias Patch.Mock.Code.Queries

  defdelegate exports(abstract_forms), to: Queries.Exports, as: :query
  defdelegate functions(abstract_forms), to: Queries.Functions, as: :query
end
