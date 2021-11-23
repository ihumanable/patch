defmodule Patch.Test.Support.User.Deadline do
  def clear do
    Application.delete_env(:patch, :deadline_test)
  end

  def delayed_put(value, milliseconds) do
    spawn(fn ->
      Process.sleep(milliseconds)
      put(value)
    end)

    :ok
  end

  def get do
    Application.get_env(:patch, :deadline_test)
  end

  def put(value) do
    Application.put_env(:patch, :deadline_test, value)
  end
end
