defmodule Patch.Mock.Code.Unit do
  alias Patch.Mock.Code
  alias Patch.Mock.Naming

  @type t :: %__MODULE__{
    abstract_forms: [Code.form()],
    compiler_options: [Code.compiler_option()],
    module: module(),
    sticky?: boolean()
  }
  defstruct [:abstract_forms, :compiler_options, :module, :sticky?]


  @spec purge(unit :: t()) :: :ok
  def purge(%__MODULE__{} = unit) do
    [
      &Naming.delegate/1,
      &Naming.facade/1,
      &Naming.original/1
    ]
    |> Enum.each(fn factory ->
      unit.module
      |> factory.()
      |> Code.purge()
    end)
  end

  @spec restore(unit :: t()) :: :ok
  def restore(%__MODULE__{} = unit) do
    :ok = purge(unit)
    :ok = Code.compile(unit.abstract_forms, unit.compiler_options)

    if unit.sticky? do
      Code.stick_module(unit.module)
    end

    :ok
  end

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(%Patch.Mock.Code.Unit{} = unit, opts) do
      concat([
        "#Patch.Mock.Code.Unit<",
        to_doc(unit.module, opts),
        ">"
      ])
    end
  end
end
