defmodule Patch.Mock.Code.Generators.Original do
  alias Patch.Mock.Code.Transform
  alias Patch.Mock.Naming

  @doc """
  Generates a new original module based on the forms of the provided module.
  """
  @spec generate(abstract_forms :: [Code.form()], module :: module()) :: [Code.form()]
  def generate(abstract_forms, module) do
    delegate_module = Naming.delegate(module)
    original_module = Naming.original(module)

    abstract_forms
    |> Transform.expose(:all)
    |> Transform.remote(delegate_module)
    |> Transform.rename(original_module)
  end
end
