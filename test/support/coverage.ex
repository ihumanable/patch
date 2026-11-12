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

  @doc """
  Cover-compiles a module from a copy of its beam file and returns the path of
  the copy.

  The test may delete or replace the copy. When the test exits, the copy is
  deleted and the module is cover-compiled from its own beam file again.
  """
  @spec compile_module_copy(module :: module()) :: Path.t()
  def compile_module_copy(module) do
    unique_name = "patch-cover-copy-#{System.pid()}-#{System.unique_integer([:positive])}"
    directory = Path.join(System.tmp_dir!(), unique_name)
    copy_path = Path.join(directory, "#{module}.beam")
    beam_path = :code.where_is_file(~c"#{module}.beam")

    :ok = File.mkdir(directory)
    :ok = File.cp(beam_path, copy_path)
    on_exit(fn -> remove_module_copy(module, directory) end)

    {:ok, ^module} = :cover.compile_beam(String.to_charlist(copy_path))
    copy_path
  end

  @doc """
  Loads a module from its beam file as plain code for the rest of the test.

  A module that was cover-compiled is cover-compiled again when the test
  exits, so a run under `mix test --cover` keeps it in the report.
  """
  @spec load_plain_module(module :: module()) :: :ok
  def load_plain_module(module) do
    if :code.which(module) == :cover_compiled do
      on_exit(fn -> compile_module(module) end)
    end

    :code.purge(module)
    {:module, ^module} = :code.load_file(module)
    :ok
  end

  @spec remove_module_copy(module :: module(), directory :: Path.t()) :: :ok
  defp remove_module_copy(module, directory) do
    :ok = compile_module(module)
    {:ok, _} = File.rm_rf(directory)
    :ok
  end

  @spec stop_cover() :: :ok
  defp stop_cover() do
    :ok = :cover.stop()
  end
end
