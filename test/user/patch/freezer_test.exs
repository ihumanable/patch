defmodule Patch.Test.User.Patch.FreezerTest do
  use ExUnit.Case
  use Patch

  alias Patch.Test.Support.User.Patch.Freezer

  describe "Internal Dependencies" do
    test "patching GenServer does not break Patch" do
      {:ok, pid} = Freezer.start_link()

      assert :ok == Freezer.work(pid)

      patch(GenServer, :call, :patched)

      assert :patched == Freezer.work(pid)

      assert_called GenServer.call(^pid, :work)
    end
  end
end
