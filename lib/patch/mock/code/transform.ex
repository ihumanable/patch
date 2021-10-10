defmodule Patch.Mock.Code.Transform do
  @moduledoc """
  This module provides the ability to transform abstract forms.

  This module delegates transformation to purpose specific Transforms modules, see those modules
  for additional details on how specific transformations work.

  - `Patch.Mock.Code.Transforms.Expose` for how private functions are exposed as public.
  - `Patch.Mock.Code.Transforms.Remote` for how local calls are made remote
  - `Patch.Mock.Code.Transforms.Rename` for how a module is renamed
  """

  alias Patch.Mock.Code.Transforms

  @type exposes :: :all | :none | Code.exports()

  defdelegate expose(abstract_forms, exposes), to: Transforms.Expose, as: :transform
  defdelegate remote(abstract_forms, module), to: Transforms.Remote, as: :transform
  defdelegate rename(abstract_forms, module), to: Transforms.Rename, as: :transform
end
