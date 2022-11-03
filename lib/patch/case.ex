defmodule Patch.Case do
  defmacro __using__(_) do
    quote do
      setup do
        debug = Application.fetch_env(:patch, :debug)
        start_supervised!(Patch.Supervisor)

        on_exit(fn ->
          Patch.Mock.Code.Freezer.empty()

          case debug do
            {:ok, value} ->
              Application.put_env(:patch, :debug, value)

            :error ->
              Application.delete_env(:patch, :debug)
          end
        end)

        :ok
      end
    end
  end
end
