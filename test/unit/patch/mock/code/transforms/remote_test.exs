defmodule Patch.Test.Unit.Patch.Mock.Code.Transforms.RemoteTest do
  use ExUnit.Case

  alias Patch.Mock.Code.Transforms.Remote

  @export_target {:attribute, 1, :export, [target: 0]}

  describe "transform/2 generated nodes" do
    test "rewritten local call is generated at the line of the call" do
      call = {:call, 7, {:atom, 7, :target}, []}
      forms = [@export_target, {:function, 3, :caller, 0, [{:clause, 3, [], [], [call]}]}]

      assert [_, {:function, _, _, _, [{:clause, _, _, _, [rewritten]}]}] =
               Remote.transform(forms, Example)

      assert {:call, 7,
              {:remote, remote_anno, {:atom, module_anno, Example}, {:atom, 7, :target}},
              []} = rewritten

      for annotation <- [remote_anno, module_anno] do
        assert :erl_anno.generated(annotation)
        assert :erl_anno.location(annotation) == 7
      end
    end

    test "rewritten local capture is generated at the line of the capture" do
      capture = {:fun, 7, {:function, :target, 0}}
      forms = [{:function, 3, :caller, 0, [{:clause, 3, [], [], [capture]}]}]

      assert [{:function, _, _, _, [{:clause, _, _, _, [rewritten]}]}] =
               Remote.transform(forms, Example)

      assert {:fun, 7,
              {:function, {:atom, module_anno, Example}, {:atom, name_anno, :target},
               {:integer, arity_anno, 0}}} = rewritten

      for annotation <- [module_anno, name_anno, arity_anno] do
        assert :erl_anno.generated(annotation)
        assert :erl_anno.location(annotation) == 7
      end
    end
  end
end
