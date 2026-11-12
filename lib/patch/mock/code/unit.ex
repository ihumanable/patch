defmodule Patch.Mock.Code.Unit do
  alias Patch.Mock.Code
  alias Patch.Mock.Code.Cover
  alias Patch.Mock.Naming

  @type t :: %__MODULE__{
    abstract_forms: [Code.form()],
    compiler_options: [Code.compiler_option()],
    cover: Cover.t() | nil,
    module: module(),
    sticky?: boolean()
  }
  defstruct [:abstract_forms, :compiler_options, :cover, :module, :sticky?]


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
  def restore(%__MODULE__{cover: nil} = unit) do
    :ok = purge(unit)
    :ok = Code.compile(unit.abstract_forms, unit.compiler_options)
    restore_stickiness(unit)
  end

  def restore(%__MODULE__{} = unit) do
    if restored?(unit) do
      # A failed expose rebuild unsticks the module after the first restore.
      restore_stickiness(unit)
    else
      cover = Cover.export_original(unit.cover)
      :ok = purge(unit)

      case Cover.restore_module(cover) do
        :ok ->
          :ok

        {:error, _reason} ->
          :ok = Code.compile(unit.abstract_forms, unit.compiler_options)
      end

      restore_stickiness(unit)
    end
  end

  ## Private

  # The server restores a unit twice. handle_call(:restore) restores it and
  # stops the server, and so does an expose whose rebuild fails; terminate/2
  # then restores the same unit again. A second restore would compile the
  # cover-compiled module from its beam file again and clear the counts that
  # the first restore imported. Before its restore the module is the facade,
  # which is loaded from a binary, and the original is loaded; the restore
  # purges the original and cover compiles the module again.
  @spec restored?(unit :: t()) :: boolean()
  defp restored?(%__MODULE__{} = unit) do
    original = Naming.original(unit.module)
    Cover.compiled?(unit.module) and :code.is_loaded(original) == false
  end

  @spec restore_stickiness(unit :: t()) :: :ok
  defp restore_stickiness(%__MODULE__{} = unit) do
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
