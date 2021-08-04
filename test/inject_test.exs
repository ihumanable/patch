defmodule Patch.Test.InjectTest do
  use ExUnit.Case
  use Patch

  alias Patch.Test.Support.Inject.Storage

  def start_storage(_) do
    storage = start_supervised!(Storage)
    {:ok, storage: storage}
  end

  describe "inject/3" do
    setup [:start_storage]

    test "top-level fields can be updated", ctx do
      assert 1 == Storage.version(ctx.storage)

      inject(ctx.storage, [:version], :injected_version)

      assert :injected_version == Storage.version(ctx.storage)
    end

    test "nested fields can be updated", ctx do
      :ok = Storage.put(ctx.storage, :test_key, :test_value)

      inject(ctx.storage, [:store, :test_key], :injected_value)

      assert {:ok, :injected_value} = Storage.get(ctx.storage, :test_key)
    end
  end
end
