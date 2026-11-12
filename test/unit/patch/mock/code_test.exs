defmodule Patch.Test.Unit.Patch.Mock.CodeTest do
  use ExUnit.Case, async: true

  alias Patch.Mock.Code

  describe "compile/2" do
    test "loads a module compiled with the option that makes the compiler return its warnings" do
      module = :patch_test_compiled_with_returned_warnings

      forms = [
        {:attribute, 1, :module, module},
        {:attribute, 1, :export, [example: 0]},
        {:function, 2, :example, 0, [{:clause, 2, [], [], [{:atom, 2, :compiled}]}]}
      ]

      on_exit(fn -> Code.purge(module) end)

      assert Code.compile(forms, [:return_warnings]) == :ok
      assert apply(module, :example, []) == :compiled
    end
  end
end
