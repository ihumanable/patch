defmodule Patch.Test.Support.Coverage do
  @moduledoc """
  Runs cover for the tests that need it.

  The suite may run under `mix test --cover`, where Mix has started cover and
  cover-compiled every module before the first test. A test leaves such a
  server running and stops only a server it started itself.
  """

  @compile {:no_warn_undefined, :cover}

  import ExUnit.Callbacks, only: [on_exit: 1]

  @doc """
  Starts cover unless it is running.

  Call it from a test or a `setup` callback. A server started here is stopped
  when the test exits; a server that was already running is left alone.
  """
  @spec start_cover() :: :ok
  def start_cover() do
    case :cover.start() do
      {:ok, _server} ->
        on_exit(&stop_cover/0)

      {:error, {:already_started, _server}} ->
        :ok
    end
  end

  @doc """
  Cover-compiles a module from its beam file in the code path.

  The beam file is found by name, so this works whether the module is loaded
  as plain code or is cover-compiled already.
  """
  @spec compile_module(module :: module()) :: :ok
  def compile_module(module) do
    beam_path = :code.where_is_file(~c"#{module}.beam")
    {:ok, ^module} = :cover.compile_beam(beam_path)
    :ok
  end

  @spec stop_cover() :: :ok
  defp stop_cover() do
    :ok = :cover.stop()
  end
end
