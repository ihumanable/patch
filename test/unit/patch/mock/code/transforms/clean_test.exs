defmodule Patch.Test.Unit.Patch.Mock.Code.Transforms.CleanTest do
  use ExUnit.Case

  alias Patch.Mock.Code.Transforms.Clean

  describe "transform/1 compile attribute handling" do
    test "retains wildcard no_auto_import when expressed as scalar" do
      forms = [
        {:attribute, 1, :compile, :no_auto_import}
      ]

      cleaned = Clean.transform(forms)

      assert cleaned == forms
    end

    test "retains wildcard no_auto_import when expressed as list" do
      forms = [
        {:attribute, 1, :compile, [:no_auto_import]}
      ]

      cleaned = Clean.transform(forms)

      assert cleaned == forms
    end

    test "retains specific no_auto_import when expressed as scalar" do
      forms = [
        {:attribute, 1, :compile, {:no_auto_import, [example: 1]}}
      ]

      cleaned = Clean.transform(forms)

      assert cleaned == forms
    end

    test "retains specific no_auto_import when expressed as list" do
      forms = [
        {:attribute, 1, :compile, [no_auto_import: [example: 1]]}
      ]

      cleaned = Clean.transform(forms)

      assert cleaned == forms
    end

    test "strips other options" do
      forms = [
        {:attribute, 1, :compile, [:no_auto_import, {:inline, [example: 1]}]}
      ]

      cleaned = Clean.transform(forms)

      assert cleaned == [
        {:attribute, 1, :compile, [:no_auto_import]}
      ]
    end

    test "removes attribute entirely if no valid options expressed as scalar" do
      forms = [
        {:attribute, 1, :compile, {:inline, [example: 1]}}
      ]

      cleaned = Clean.transform(forms)

      assert cleaned == []
    end

    test "removes attribute entirely if no valid options expressed as list" do
      forms = [
        {:attribute, 1, :compile, [{:inline, [example: 1]}]}
      ]

      cleaned = Clean.transform(forms)

      assert cleaned == []
    end
  end
end
