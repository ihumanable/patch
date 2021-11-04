defmodule Patch.Test.Support.User.Replace.Validator do
  use GenServer

  ## Client

  def child_spec(options) do
    validation_function = Keyword.get(options, :validation_function, &no_op_validation/2)
    options = Keyword.drop(options, [:validation_function])

    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [validation_function, options]}
    }
  end

  def start_link(validation_function, options) do
    GenServer.start_link(__MODULE__, validation_function, options)
  end

  ## Server

  def init(validation_function) do
    {:ok, validation_function}
  end

  def handle_call({:validate, key, value}, _from, validation_function) do
    {:reply, validation_function.(key, value), validation_function}
  end

  ## Private

  defp no_op_validation(_key, _value) do
    :ok
  end
end
