defmodule Patch.Mock.Code.Generate do
  @moduledoc """
  This module provides the ability to generate derivative modules based on a target module.

  This module delegates code generation to purpose specific Generator modules, see those modules
  for additional details on how specific generation works.

  - `Patch.Mock.Code.Generators.Delegate` for how `delegate` modules are generated
  - `Patch.Mock.Code.Generators.Facade` for how `facade` modules are generated
  - `Patch.Mock.Code.Generators.Original` for how `original` modules are generated
  """

  alias Patch.Mock.Code.Generators

  defdelegate delegate(abstract_forms, module, exports), to: Generators.Delegate, as: :generate
  defdelegate facade(abstract_forms, module, exports), to: Generators.Facade, as: :generate
  defdelegate original(abstract_forms, module, exports), to: Generators.Original, as: :generate
end
