defmodule Patch.Test.ListenAndInjectTest do
  use ExUnit.Case
  use Patch

  alias Patch.Test.Support.Inject.Storage
  alias Patch.Test.Support.Inject.Validator

  def start_storage(_) do
    validator = start_supervised!(Validator)
    storage = start_supervised!({Storage, validator: validator})

    {:ok, storage: storage, validator: validator}
  end

  describe "listen/3 and inject/3" do
    setup [:start_storage]

    test "validator can be listened to and injected into storage", ctx do
      {:ok, listener} = listen(:validator, ctx.validator)
      inject(ctx.storage, [:validator], listener)

      Storage.put(ctx.storage, :test_key, :test_value)

      assert_receive {:validator, {GenServer, :call, {:validate, :test_key, :test_value}}}
      assert_receive {:validator, {GenServer, :reply, :ok}}
    end
  end
end
