defmodule Patch.Test.Unit.Patch.Mock.Code.GenerateTest do
  use ExUnit.Case

  alias Patch.Mock.Code
  alias Patch.Mock.Code.Generate
  alias Patch.Test.Support.Unit.Annotated

  @annotation_keys [:generated, :location, :file, :text, :record]

  describe "original/3" do
    test "gives every annotation of the generated forms a location" do
      {:ok, forms} = Code.abstract_forms(Annotated)
      exports = Code.exports(forms, Annotated, :all)

      original = Generate.original(forms, Annotated, exports)

      located? = fn annotation -> :erl_anno.location(annotation) != :undefined end

      annotations = collect_annotations(original)

      assert annotations != []
      assert Enum.reject(annotations, located?) == []
    end

    test "marks the replaced module and export attributes as generated at their original location" do
      {:ok, forms} = Code.abstract_forms(Annotated)
      exports = Code.exports(forms, Annotated, :all)

      original = Generate.original(forms, Annotated, exports)

      for name <- [:module, :export] do
        replaced = attribute_annotation(forms, name)
        generated = attribute_annotation(original, name)

        assert :erl_anno.generated(generated)
        assert :erl_anno.location(generated) == :erl_anno.location(replaced)
      end
    end
  end

  defp attribute_annotation(forms, name) do
    Enum.find_value(forms, fn
      {:attribute, annotation, ^name, _} -> annotation
      _ -> nil
    end)
  end

  defp collect_annotations(term) when is_tuple(term) and tuple_size(term) >= 2 do
    annotation = elem(term, 1)
    own = if annotation?(annotation), do: [annotation], else: []
    own ++ collect_children(term)
  end

  defp collect_annotations(term), do: collect_children(term)

  defp collect_children(term) when is_tuple(term) do
    term
    |> Tuple.to_list()
    |> Enum.flat_map(&collect_annotations/1)
  end

  defp collect_children(term) when is_list(term), do: Enum.flat_map(term, &collect_annotations/1)
  defp collect_children(_), do: []

  defp annotation?([_ | _] = term), do: Enum.all?(term, &annotation_entry?/1)
  defp annotation?(_), do: false

  defp annotation_entry?({key, _}), do: key in @annotation_keys
  defp annotation_entry?(_), do: false
end
