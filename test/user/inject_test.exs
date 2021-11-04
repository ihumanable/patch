defmodule Patch.Test.User.InjectTest do
  use ExUnit.Case
  use Patch

  alias Patch.Test.Support.User.Replace.Storage
  alias Patch.Test.Support.User.Replace.Validator

  def start_storage(_) do
    validator = start_supervised!(Validator)
    storage = start_supervised!({Storage, validator: validator})

    {:ok, storage: storage, validator: validator}
  end

  describe "inject/4" do
    setup [:start_storage]

    test "validator listener can be injected into storage", ctx do
      inject(:validator, ctx.storage, [:validator])

      Storage.put(ctx.storage, :test_key, :test_value)

      assert_receive {:validator, {GenServer, :call, {:validate, :test_key, :test_value}, _}}
      assert_receive {:validator, {GenServer, :reply, :ok, _}}
    end
  end
end
