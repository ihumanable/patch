defmodule Patch.Test.InjectTest do
  use ExUnit.Case
  use Patch

  alias Patch.Test.Support.Inject.Storage

  def start_anonymous_storage(_) do
    storage = start_supervised!(Storage)
    {:ok, storage: storage}
  end

  def start_named_storage(_) do
    storage = start_supervised!({Storage, name: Storage})
    {:ok, storage: storage}
  end

  describe "inject/3 with a named process" do
    setup [:start_named_storage]

    test "top-level fields can be updated via pid" do
      assert 1 == Storage.version(Storage)

      inject(Storage, [:version], :injected_version)

      assert :injected_version == Storage.version(Storage)
    end

    test "nested fields can be updated" do
      :ok = Storage.put(Storage, :test_key, :test_value)

      inject(Storage, [:store, :test_key], :injected_value)

      assert {:ok, :injected_value} = Storage.get(Storage, :test_key)
    end
  end

  describe "inject/3 with an anonymous process" do
    setup [:start_anonymous_storage]

    test "top-level fields can be updated via pid", ctx do
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
