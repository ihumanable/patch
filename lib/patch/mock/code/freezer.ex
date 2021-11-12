defmodule Patch.Mock.Code.Freezer do
  @moduledoc """
  The Code Freezer is a registry that can be used to register and use modules
  that might be frozen.

  Modules that Patch relies on must be freezable so that the end-user can Patch
  them and the frozen versions are still available for internal use.
  """

  alias Patch.Mock.Code
  alias Patch.Mock.Naming

  @freezable [GenServer]

  @doc """
  Destroy all frozen modules
  """
  @spec empty() :: :ok
  def empty() do
    __MODULE__
    |> Application.get_all_env()
    |> Enum.each(fn {key, frozen} ->
      Code.purge(frozen)
      Application.delete_env(__MODULE__, key)
    end)
  end

  @doc """
  Get the possibly-frozen module to use for a module.

  If the module is frozen then the frozen name will be returned.

  If the module is not frozen then the module is returned.s
  """
  @spec get(module :: module()) :: module()
  def get(module) do
    Application.get_env(__MODULE__, module, module)
  end

  @doc """
  Puts a module into the freezer.

  The module must be freezable.  Repeated calls for frozen modules are no-ops.
  """
  @spec put(module :: module()) :: :ok
  def put(module) when module in @freezable do
    case Application.fetch_env(__MODULE__, module) do
      {:ok, _} ->
        :ok

      :error ->
        :ok = Code.freeze(module)
        Application.put_env(__MODULE__, module, Naming.frozen(module))
    end
  end

  def put(_) do
    :ok
  end
end
