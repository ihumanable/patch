defmodule Patch.Test.Unit.Patch.Mock.Code.Queries.ExportsTest do
  use ExUnit.Case

  alias Patch.Mock.Code.Queries.Exports

  describe "query/1" do
    test "handles functions with multiple arities declared across multiple exports" do
      forms = [
        {:attribute, 1, :export, [a: 1]},
        {:attribute, 1, :export, [a: 2]}
      ]

      expected = Enum.sort([a: 1, a: 2])

      actual =
        forms
        |> Exports.query()
        |> Enum.sort()

      assert expected == actual
    end
  end
end
