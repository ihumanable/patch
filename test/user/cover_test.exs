defmodule Patch.Test.User.CoverTest do
  use ExUnit.Case, async: false
  use Patch

  import ExUnit.CaptureLog

  alias Patch.Mock.Naming
  alias Patch.Test.Support.Coverage
  alias Patch.Test.Support.User.Cover.Counted
  alias Patch.Test.Support.User.Cover.Plain
  alias Patch.Test.Support.User.Cover.Unpatched

  setup do
    :ok = Coverage.start_cover()
  end

  describe "a cover-compiled module" do
    setup do
      :ok = Coverage.compile_module(Counted)
    end

    test "counts the lines run while patched, private functions included, and no body of a mocked call" do
      Counted.public_function(1)
      Counted.public_function(7)
      expected_counts = take_line_counts()

      patch(Counted, :mocked_function, 0)

      assert Counted.public_function(1) == :small
      assert Counted.public_function(7) == :large
      assert Counted.mocked_function(2) == 0

      stop_supervised!(Patch.Supervisor)

      assert line_counts() == expected_counts
    end

    test "keeps the counts gathered before the patch" do
      Counted.public_function(1)
      Counted.public_function(7)
      expected_counts = take_line_counts()

      Counted.public_function(1)
      patch(Counted, :mocked_function, 0)
      Counted.public_function(7)
      stop_supervised!(Patch.Supervisor)

      assert line_counts() == expected_counts
    end

    test "is cover-compiled by the same cover server after the patch and keeps counting" do
      Counted.public_function(1)
      Counted.public_function(7)
      expected_counts = take_line_counts()
      cover_server = Process.whereis(:cover_server)

      patch(Counted, :mocked_function, 0)
      Counted.public_function(1)
      stop_supervised!(Patch.Supervisor)
      Counted.public_function(7)

      assert :code.which(Counted) == :cover_compiled
      assert Process.whereis(:cover_server) == cover_server
      assert line_counts() == expected_counts
    end

    test "keeps the counts through an explicit restore followed by the end of the test and logs nothing" do
      Counted.public_function(1)
      Counted.mocked_function(2)
      Counted.public_function(7)
      expected_counts = take_line_counts()

      patch(Counted, :mocked_function, 0)
      Counted.public_function(1)
      log = capture_log(fn -> restore(Counted) end)
      Counted.mocked_function(2)
      stop_supervised!(Patch.Supervisor)
      Counted.public_function(7)

      assert log == ""
      assert line_counts() == expected_counts
    end

    test "keeps the counts through expose" do
      Counted.public_function(1)
      Counted.public_function(7)
      expected_counts = take_line_counts()

      patch(Counted, :mocked_function, 0)
      Counted.public_function(1)
      :ok = expose(Counted, :all)
      Counted.public_function(7)
      stop_supervised!(Patch.Supervisor)

      assert line_counts() == expected_counts
    end

    test "stops the server with the rebuild error of a failed expose and keeps the counts through it and a later patch" do
      Counted.public_function(1)
      Counted.public_function(7)
      Counted.public_function(3)
      expected_counts = take_line_counts()

      patch(Counted, :mocked_function, 0)
      Counted.public_function(1)
      server = Process.whereis(Naming.server(Counted))
      monitor = Process.monitor(server)
      capture_log(fn -> assert {:error, _} = expose(Counted, missing_function: 1) end)
      Counted.public_function(7)

      assert_receive {:DOWN, ^monitor, :process, ^server,
                      {:error, {:abstract_forms_invalid, _, _}}}

      assert :code.which(Counted) == :cover_compiled

      patch(Counted, :mocked_function, 0)
      Counted.public_function(3)
      stop_supervised!(Patch.Supervisor)

      assert line_counts() == expected_counts
    end

    test "counts the body of a function restored on its own" do
      Counted.mocked_function(2)
      Counted.public_function(1)
      expected_counts = take_line_counts()

      patch(Counted, :mocked_function, 0)
      Counted.mocked_function(2)
      restore(Counted, :mocked_function)

      assert Counted.mocked_function(2) == 5

      Counted.public_function(1)
      stop_supervised!(Patch.Supervisor)

      assert line_counts() == expected_counts
    end

    test "adds up the counts of several patch cycles" do
      for value <- [1, 7, 3] do
        Counted.public_function(value)
        Counted.mocked_function(value)
      end

      expected_counts = take_line_counts()

      for value <- [1, 7, 3] do
        run_patch_cycle(value)
      end

      assert line_counts() == expected_counts
    end

    test "imports the counts without recording the module as imported" do
      patch(Counted, :mocked_function, 0)
      Counted.public_function(1)
      restore(Counted)

      refute Counted in :cover.imported_modules()
    end

    test "deletes the directory that holds the exports when the patch ends" do
      export_directories = list_export_directories()
      patch(Counted, :mocked_function, 0)
      [directory] = list_export_directories() -- export_directories

      assert File.dir?(directory)

      restore(Counted)

      refute File.exists?(directory)
    end

    test "is restored with no original or export directory left when cover compiles it again during the patch" do
      export_directories = list_export_directories()

      patch(Counted, :mocked_function, 0)
      :ok = Coverage.compile_module(Counted)
      stop_supervised!(Patch.Supervisor)

      assert :code.which(Naming.original(Counted)) == :non_existing
      assert :code.which(Counted) == :cover_compiled
      assert list_export_directories() == export_directories
    end

    test "is restored when its cover-compiled original is unloaded during the patch" do
      original = Naming.original(Counted)
      patch(Counted, :mocked_function, 0)

      # Cover unloads a cover-compiled module this way when it stops. The delete
      # fails while old code from an earlier patch is loaded, so a purge goes first.
      :code.purge(original)
      :code.delete(original)
      :code.purge(original)

      assert :code.is_loaded(original) == false

      stop_supervised!(Patch.Supervisor)

      assert :code.which(Counted) == :cover_compiled
    end

    test "takes the plain path with a warning when the beam file that cover compiled it from is gone" do
      copy_path = Coverage.compile_module_copy(Counted)
      File.rm!(copy_path)
      cover_server = Process.whereis(:cover_server)

      log = capture_log(fn -> patch(Counted, :mocked_function, 0) end)

      assert Counted.public_function(1) == :small
      assert :code.which(Naming.original(Counted)) != :cover_compiled

      restore(Counted)

      assert log =~ "coverage of #{inspect(Counted)}"
      assert log =~ inspect({:file_error, String.to_charlist(copy_path), :enoent})
      assert :cover.analyse(Counted, :calls, :line) == {:error, {:not_cover_compiled, Counted}}
      assert Process.whereis(:cover_server) == cover_server
    end

    test "is loaded as plain code with a warning when its beam file is gone at the restore" do
      copy_path = Coverage.compile_module_copy(Counted)
      patch(Counted, :mocked_function, 0)
      File.rm!(copy_path)
      cover_server = Process.whereis(:cover_server)

      log = capture_log(fn -> restore(Counted) end)
      analysis_log = capture_log(fn -> :cover.analyse(:coverage, :line) end)

      # A call would load the module from its beam file, so check first that it is loaded.
      assert {:file, _} = :code.is_loaded(Counted)
      assert Counted.public_function(7) == :large
      assert :code.which(Counted) != :cover_compiled
      assert log =~ "coverage of #{inspect(Counted)}"
      assert log =~ inspect({:file_error, String.to_charlist(copy_path), :enoent})
      refute analysis_log =~ inspect(Counted)
      assert Process.whereis(:cover_server) == cover_server
    end

    test "keeps its counts once and leaves no original behind when the patch fails after its counts are exported" do
      Counted.public_function(1)
      Counted.public_function(7)
      expected_counts = take_line_counts()
      cover_server = Process.whereis(:cover_server)
      export_directories = list_export_directories()

      Counted.public_function(1)
      capture_log(fn -> assert {:error, _} = expose(Counted, missing_function: 1) end)
      Counted.public_function(7)
      analysis_log = capture_log(fn -> :cover.analyse(:coverage, :line) end)

      assert :code.which(Naming.original(Counted)) == :non_existing
      refute analysis_log =~ inspect(Counted)
      assert list_export_directories() == export_directories
      assert Process.whereis(:cover_server) == cover_server
      assert line_counts() == expected_counts
    end

    test "stays cover-compiled with a warning per failed step when the directory of its exports is removed during the patch" do
      counts_without_calls = line_counts()
      export_directories = list_export_directories()
      Counted.public_function(1)
      patch(Counted, :mocked_function, 0)
      Counted.public_function(7)
      [directory] = list_export_directories() -- export_directories
      File.rm_rf!(directory)
      cover_server = Process.whereis(:cover_server)

      log = capture_log(fn -> restore(Counted) end)

      assert count_warnings(log) == 3
      assert :code.which(Counted) == :cover_compiled
      assert Process.whereis(:cover_server) == cover_server
      assert line_counts() == counts_without_calls
    end

    test "keeps the counts through an expose that raises after the restore" do
      Counted.public_function(1)
      Counted.public_function(7)
      expected_counts = take_line_counts()
      cover_server = Process.whereis(:cover_server)

      patch(Counted, :mocked_function, 0)
      Counted.public_function(1)
      server = Process.whereis(Naming.server(Counted))
      monitor = Process.monitor(server)
      log = capture_log(fn -> catch_exit(expose(Counted, [:not_a_pair])) end)

      assert_receive {:DOWN, ^monitor, :process, ^server, {:function_clause, _}}

      Counted.public_function(7)

      assert count_warnings(log) == 0
      assert :code.which(Counted) == :cover_compiled
      assert Process.whereis(:cover_server) == cover_server
      assert line_counts() == expected_counts
    end

    test "keeps the cover server and the counts of every module when File.write is patched to do nothing" do
      :ok = Coverage.compile_module(Unpatched)
      Unpatched.example(1)
      unpatched_counts = line_counts(Unpatched)
      Counted.public_function(1)
      Counted.public_function(7)
      expected_counts = take_line_counts()
      cover_server = Process.whereis(:cover_server)

      patch(File, :write, :ok)
      patch(Counted, :mocked_function, 0)
      Counted.public_function(1)
      restore(Counted)
      Counted.public_function(7)

      assert Process.whereis(:cover_server) == cover_server
      assert line_counts(Unpatched) == unpatched_counts
      assert line_counts() == expected_counts
    end

    test "keeps the counts when File.read is patched during the patch" do
      Counted.public_function(1)
      Counted.public_function(7)
      expected_counts = take_line_counts()

      patch(Counted, :mocked_function, 0)
      Counted.public_function(1)
      patch(File, :read, {:ok, "not an export file"})
      restore(Counted)
      Counted.public_function(7)

      assert line_counts() == expected_counts
    end

    test "keeps the counts and logs nothing when TMPDIR names no directory" do
      Counted.public_function(1)
      Counted.public_function(7)
      expected_counts = take_line_counts()
      missing_name = "patch-cover-missing-#{System.pid()}-#{System.unique_integer([:positive])}"
      missing_directory = Path.join(System.tmp_dir!(), missing_name)
      put_temporary_directory(missing_directory)

      Counted.public_function(1)
      log = capture_log(fn -> patch(Counted, :mocked_function, 0) end)
      Counted.public_function(7)
      stop_supervised!(Patch.Supervisor)

      assert log == ""
      assert line_counts() == expected_counts
    end

    test "is patched as plain code with a warning when no directory for its exports can be created" do
      unwritable_directory = create_unwritable_directory()
      on_exit(fn -> Coverage.compile_module(Counted) end)
      put_temporary_directory(unwritable_directory)

      log = capture_log([level: :warning], fn -> patch(Counted, :mocked_function, 0) end)

      assert Counted.mocked_function(2) == 0
      assert :code.which(Naming.original(Counted)) != :cover_compiled
      assert log =~ "coverage of #{inspect(Counted)}"
      assert log =~ unwritable_directory
      assert log =~ inspect(:eacces)
    end

    test "is sticky after the patch ends when it was stuck after cover compiled it" do
      stick_module(Counted)

      patch(Counted, :mocked_function, 0)
      stop_supervised!(Patch.Supervisor)

      assert :code.is_sticky(Counted)
      assert :code.which(Counted) == :cover_compiled
    end

    test "is sticky after a failed expose when it was stuck after cover compiled it" do
      stick_module(Counted)

      patch(Counted, :mocked_function, 0)
      server = Process.whereis(Naming.server(Counted))
      monitor = Process.monitor(server)
      capture_log(fn -> assert {:error, _} = expose(Counted, missing_function: 1) end)

      assert_receive {:DOWN, ^monitor, :process, ^server, _reason}
      assert :code.is_sticky(Counted)
    end

    @tag :kills_cover_server
    test "is patched as plain code with a warning when the cover server dies during a call" do
      kill_cover_server()
      dying_server = spawn(&exit_on_first_request/0)
      Process.register(dying_server, :cover_server)

      log = capture_log(fn -> patch(Counted, :mocked_function, 0) end)

      assert Counted.mocked_function(2) == 0
      assert :code.which(Naming.original(Counted)) != :cover_compiled
      assert log =~ "coverage of #{inspect(Counted)}"
      assert log =~ inspect(:cover_exited)
    end

    test "leaves an original whose source cover finds when its mock server is killed" do
      export_directories = list_export_directories()
      output_path = Path.join(create_output_directory(), "original.html")
      options = [:html, outfile: String.to_charlist(output_path)]
      on_exit(fn -> remove_killed_patch(Counted, export_directories) end)

      patch(Counted, :mocked_function, 0)
      Counted.public_function(1)
      kill_mock_server(Counted)

      assert {:ok, _} = :cover.analyse_to_file(Naming.original(Counted), options)
    end

    test "leaves no call in the history of a spied File" do
      spy(File)

      patch(Counted, :mocked_function, 0)
      Counted.public_function(1)
      restore(Counted)

      assert history(File) == []
    end

    test "leaves no collection failure of the module or its original to a following analysis of all modules" do
      patch(Counted, :mocked_function, 0)
      Counted.public_function(1)
      stop_supervised!(Patch.Supervisor)

      log = capture_log(fn -> :cover.analyse(:coverage, :line) end)

      refute log =~ inspect(Counted)
    end
  end

  describe "a cover-compiled Erlang module" do
    setup do
      :ok = Coverage.compile_module(:erlang_unsticky)
    end

    test "keeps the counts gathered before and while it is spied" do
      :erlang_unsticky.example_function()
      :erlang_unsticky.example_function()
      expected_counts = take_line_counts(:erlang_unsticky)

      :erlang_unsticky.example_function()
      spy(:erlang_unsticky)
      :erlang_unsticky.example_function()
      stop_supervised!(Patch.Supervisor)

      assert :code.which(:erlang_unsticky) == :cover_compiled
      assert line_counts(:erlang_unsticky) == expected_counts
    end
  end

  describe "a module that is not cover-compiled" do
    test "gets a plain original and is plain after the restore while cover runs" do
      :ok = Coverage.load_plain_module(Plain)

      patch(Plain, :example, :patched)

      assert :code.which(Naming.original(Plain)) != :cover_compiled

      restore(Plain)

      assert :code.which(Plain) != :cover_compiled
    end

    test "gets the rebuild error of a patch that fails while cover runs" do
      :ok = Coverage.load_plain_module(Plain)

      capture_log(fn -> send(self(), expose(Plain, missing_function: 1)) end)

      assert_received {:error, {:abstract_forms_invalid, _, _}}
    end
  end

  ## Private

  defp line_counts(module \\ Counted) do
    {:ok, counts} = :cover.analyse(module, :calls, :line)
    counts
  end

  defp count_warnings(log) do
    matches = :binary.matches(log, "coverage of #{inspect(Counted)}")
    length(matches)
  end

  # Patch keeps the exports of a patched module in such a directory.
  defp list_export_directories() do
    pattern = Path.join(System.tmp_dir!(), "patch-cover-#{System.pid()}-*")
    Path.wildcard(pattern)
  end

  # Patch takes the directory, as System.tmp_dir/0 does, but cannot create a
  # directory in it.
  defp create_unwritable_directory() do
    unique_name = "patch-cover-unwritable-#{System.pid()}-#{System.unique_integer([:positive])}"
    directory = Path.join(System.tmp_dir!(), unique_name)
    File.mkdir!(directory)
    File.chmod!(directory, 0o600)
    on_exit(fn -> File.rm_rf!(directory) end)
    directory
  end

  defp put_temporary_directory(directory) do
    previous_directory = System.get_env("TMPDIR")
    on_exit(fn -> restore_temporary_directory(previous_directory) end)
    System.put_env("TMPDIR", directory)
  end

  defp restore_temporary_directory(nil) do
    System.delete_env("TMPDIR")
  end

  defp restore_temporary_directory(directory) do
    System.put_env("TMPDIR", directory)
  end

  defp create_output_directory() do
    unique_name = "patch-cover-output-#{System.pid()}-#{System.unique_integer([:positive])}"
    directory = Path.join(System.tmp_dir!(), unique_name)
    File.mkdir!(directory)
    on_exit(fn -> File.rm_rf!(directory) end)
    directory
  end

  defp kill_cover_server() do
    cover_server = Process.whereis(:cover_server)
    monitor = Process.monitor(cover_server)
    Process.exit(cover_server, :kill)
    assert_receive {:DOWN, ^monitor, :process, ^cover_server, :killed}
  end

  defp kill_mock_server(module) do
    server = Process.whereis(Naming.server(module))
    monitor = Process.monitor(server)
    Process.exit(server, :kill)
    assert_receive {:DOWN, ^monitor, :process, ^server, :killed}
  end

  # A killed mock server restores nothing, so the test removes the generated
  # modules, has cover forget the original, compiles the module for cover
  # again and deletes the export directory.
  defp remove_killed_patch(module, export_directories) do
    original = Naming.original(module)

    for generated <- [Naming.delegate(module), original, module] do
      Patch.Mock.Code.purge(generated)
    end

    false = :cover.is_compiled(original)
    :ok = Coverage.compile_module(module)

    for directory <- list_export_directories() -- export_directories do
      File.rm_rf!(directory)
    end
  end

  # Stands in for a cover server that dies while it handles a request.
  defp exit_on_first_request() do
    receive do
      _request -> exit(:died_during_request)
    end
  end

  defp stick_module(module) do
    :code.stick_mod(module)
    on_exit(fn -> :code.unstick_mod(module) end)
  end

  defp take_line_counts(module \\ Counted) do
    counts = line_counts(module)
    :ok = :cover.reset(module)
    counts
  end

  defp run_patch_cycle(value) do
    patch(Counted, :mocked_function, 0)
    Counted.public_function(value)
    restore(Counted)
    Counted.mocked_function(value)
  end
end
