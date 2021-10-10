defmodule Patch.Mock.Code.Generators.Delegate do
  @moduledoc """
  Generator for `delegate` modules.

  `delegate` modules are generated by taking the `target` module and creating a  stub function for
  each function in the module that calls the `Patch.Mock.Server`'s `delegate/3` function.

  The `delegate` module will also expose every function in the module regardless of the original
  visibility.
  """

  @generated [generated: true]

  alias Patch.Mock.Code
  alias Patch.Mock.Code.Transform
  alias Patch.Mock.Naming

  @doc """
  Generates a new delegate module based on the forms of a provided module.
  """
  @spec generate(abstract_forms :: [Code.form()], module :: module) :: [Code.form()]
  def generate(abstract_forms, module) do
    delegate_name = Naming.delegate(module)

    abstract_forms
    |> Enum.map(fn
      {:function, _, name, arity, _} ->
        function(module, name, arity)

      other ->
        other
    end)
    |> Transform.expose(:all)
    |> Transform.rename(delegate_name)
  end

  ## Private

  defp arguments(0) do
    cons([])
  end

  defp arguments(arity) do
    1..arity
    |> Enum.to_list()
    |> cons()
  end

  defp cons([]), do: {nil, @generated}

  defp cons([head | tail]) do
    {:cons, @generated, {:var, @generated, :"_arg#{head}"}, cons(tail)}
  end

  defp body(module, name, arity) do
    [
      {:call, @generated,
       {:remote, @generated, {:atom, @generated, Patch.Mock.Server},
        {:atom, @generated, :delegate}},
       [
         {:atom, @generated, module},
         {:atom, @generated, name},
         arguments(arity)
       ]}
    ]
  end

  defp function(module, name, arity) do
    clause = {
      :clause,
      @generated,
      patterns(arity),
      [],
      body(module, name, arity)
    }

    {:function, @generated, name, arity, [clause]}
  end

  defp patterns(0) do
    []
  end

  defp patterns(arity) do
    Enum.map(1..arity, fn position ->
      {:var, @generated, :"_arg#{position}"}
    end)
  end
end
