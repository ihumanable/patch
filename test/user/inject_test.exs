defmodule Patch.Test.User.InjectTest do
  use ExUnit.Case
  use Patch

  alias Patch.Test.Support.User.Inject.Caller

  describe "inject/4" do
    test "Target listener can be injected into the Caller Process" do
      bonus = 5
      multiplier = 10

      {:ok, caller_pid} = Caller.start_link(bonus, multiplier)

      inject(:target, caller_pid, [:target_pid])

      assert Caller.calculate(caller_pid, 7) == 75   # (7 * 10) + 5

      assert_receive {:target, {GenServer, :call, {:work, 7}, from}}
      assert_receive {:target, {GenServer, :reply, 70, ^from}}
    end
  end
end
