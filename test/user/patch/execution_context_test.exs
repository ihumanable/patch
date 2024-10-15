defmodule Patch.Test.User.Patch.ExecutionContextTest do
  use ExUnit.Case
  use Patch

  alias Patch.Test.Support.User.Patch.ExecutionContext

  describe "execution context" do
    test "patch executes the mock function in the caller's execution context" do
      assert ExecutionContext.example() == :original

      patch(ExecutionContext, :example, fn -> self() end)

      assert ExecutionContext.example() == self()
    end
  end
end
