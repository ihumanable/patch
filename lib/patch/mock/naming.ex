defmodule Patch.Mock.Naming do
  @doc """
  Canonical name for the delegate module for a provided module.
  """
  @spec delegate(module :: module()) :: module()
  def delegate(module) do
    Module.concat(Patch.Mock.Delegate.For, module)
  end

  @doc """
  Canonical name for the facade module for a provided module.

  The facade module simply takes on the name of the provided module.
  """
  @spec facade(module :: module()) :: module()
  def facade(module) do
    module
  end

  @doc """
  Canonical name for the original module for a provided module.
  """
  @spec original(module :: module()) :: module()
  def original(module) do
    Module.concat(Patch.Mock.Original.For, module)
  end

  @doc """
  Canonical name for the server process for a provided module.
  """
  @spec server(module :: module()) :: GenServer.name()
  def server(module) do
    Module.concat(Patch.Mock.Server.For, module)
  end
end
