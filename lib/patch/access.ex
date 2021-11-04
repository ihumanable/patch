defmodule Patch.Access do

  def get(target, keys, default \\ nil)

  def get(%{} = target, [key], default) do
    Map.get(target, key, default)
  end

  def get(%{} = target, [key | rest], default) do
    case Map.fetch(target, key) do
      {:ok, value} ->
        get(value, rest, default)

      :error ->
        default
    end
  end

  def fetch(%{} = target, [key]) do
    Map.fetch(target, key)
  end

  def fetch(%{} = target, [key | rest]) do
    with {:ok, value} <- Map.fetch(target, key) do
      fetch(value, rest)
    end
  end

  def put(%{} = target, [key], value) do
    Map.put(target, key, value)
  end

  def put(%{} = target, [key | rest], value) do
    inner = get(target, [key])
    updated = put(inner, rest, value)
    Map.put(target, key, updated)
  end
end
