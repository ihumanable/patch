defmodule Patch.Mock.Code.Transform do
  @moduledoc """
  This module provides the ability to transform abstract forms.

  This module delegates transformation to purpose specific Transforms modules, see those modules
  for additional details on how specific transformations work.

  - `Patch.Mock.Code.Transforms.Clean` for how a module is prepared for generation.
  - `Patch.Mock.Code.Transforms.Export` for how exports are rewritten
  - `Patch.Mock.Code.Transforms.Filter` for how functions are filtered
  - `Patch.Mock.Code.Transforms.Remote` for how local calls are made remote
  - `Patch.Mock.Code.Transforms.Rename` for how a module is renamed
  """

  alias Patch.Mock.Code.Transforms

  defdelegate clean(abstract_forms), to: Transforms.Clean, as: :transform
  defdelegate export(abstract_forms, exports), to: Transforms.Export, as: :transform
  defdelegate filter(abstract_forms, exports), to: Transforms.Filter, as: :transform
  defdelegate remote(abstract_forms, module), to: Transforms.Remote, as: :transform
  defdelegate rename(abstract_forms, module), to: Transforms.Rename, as: :transform
end
