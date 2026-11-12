defmodule Patch.Test.Unit.Patch.Mock.Code.CoverTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  alias Patch.Mock.Code.Cover
  alias Patch.Mock.Naming
  alias Patch.Test.Support.Coverage

  alias Patch.Test.Support.Unit.Cover.ExportRecordsLongerThanTwoHundredFiftyFiveBytesAfterCompressionCarryASizeRecordInFrontOfThem,
    as: LongNames

  alias Patch.Test.Support.Unit.Cover.Source
  alias Patch.Test.Support.Unit.Cover.Target

  setup do
    unique_name = "patch-cover-test-#{System.pid()}-#{System.unique_integer([:positive])}"
    directory = Path.join(System.tmp_dir!(), unique_name)
    File.mkdir_p!(directory)
    on_exit(fn -> File.rm_rf!(directory) end)

    [directory: directory]
  end

  describe "read_terms/1 and write_terms/2" do
    test "write back a file cover exported, records over 255 bytes included, byte for byte",
         ctx do
      %{directory: directory} = ctx

      :ok = Coverage.start_cover()
      :ok = Coverage.compile_module(LongNames)
      [{function, 1}] = LongNames.__info__(:functions)
      apply(LongNames, function, [1])

      export_path = Path.join(directory, "export.coverdata")
      copy_path = Path.join(directory, "copy.coverdata")
      :ok = :cover.export(export_path, LongNames)
      export = File.read!(export_path)

      assert :binary.match(export, "$size") != :nomatch

      {:ok, terms} = Cover.read_terms(export_path)
      :ok = Cover.write_terms(copy_path, terms)

      assert File.read!(copy_path) == export
    end

    test "frame a record of 255 bytes with its length and a longer one with a '$size' record, and read both back",
         ctx do
      %{directory: directory} = ctx

      short_term = distinct_bytes(249)
      long_term = distinct_bytes(250)
      short_record = :erlang.term_to_binary(short_term, [:compressed])
      long_record = :erlang.term_to_binary(long_term, [:compressed])
      size_record = :erlang.term_to_binary({:"$size", 256})
      path = Path.join(directory, "boundary.coverdata")

      assert byte_size(short_record) == 255
      assert byte_size(long_record) == 256

      :ok = Cover.write_terms(path, [short_term, long_term])

      assert File.read!(path) ==
               <<255, short_record::binary, byte_size(size_record), size_record::binary,
                 long_record::binary>>

      assert Cover.read_terms(path) == {:ok, [short_term, long_term]}
    end

    test "return the error of a file that cannot be read", ctx do
      %{directory: directory} = ctx

      missing_path = Path.join(directory, "missing.coverdata")

      assert Cover.read_terms(missing_path) == {:error, :enoent}
    end
  end

  describe "retarget_terms/3" do
    test "renames the module in bump keys and clause entries and keeps a function named after the source" do
      terms = [
        {{:bump, Source, :double, 1, 1, 3}, 2},
        {{:bump, Source, Source, 1, 1, 7}, 1},
        {Source, [{Source, :double, 1, 1, 1}, {Source, Source, 1, 1, 1}]}
      ]

      retargeted = [
        {{:bump, Target, :double, 1, 1, 3}, 2},
        {{:bump, Target, Source, 1, 1, 7}, 1},
        {Target, [{Target, :double, 1, 1, 1}, {Target, Source, 1, 1, 1}]}
      ]

      assert Cover.retarget_terms(terms, Source, Target) == {retargeted, []}
    end

    test "drops file terms and reports terms of other shapes or other modules" do
      file_term = {:file, Source, ~c"/project/lib/source.ex"}
      bump = {{:bump, Source, :double, 1, 1, 3}, 2}

      unknown_terms = [
        {:counters, Source, [2, 1]},
        {{:bump, :other_module, :double, 1, 1, 3}, 2},
        {Source, [{Source, :double, 1, 1, 1}, {:other_module, :double, 1, 1, 1}]},
        {Source, :not_a_clause_list}
      ]

      assert Cover.retarget_terms([file_term, bump | unknown_terms], Source, Target) ==
               {[{{:bump, Target, :double, 1, 1, 3}, 2}], unknown_terms}
    end

    test "moves the counts of the source to the same lines and functions of the target", ctx do
      %{directory: directory} = ctx

      :ok = Coverage.start_cover()
      :ok = Coverage.compile_module(Source)
      :ok = Coverage.compile_module(Target)

      call_functions(Target)
      {:ok, expected_lines} = :cover.analyse(Target, :calls, :line)
      {:ok, expected_functions} = :cover.analyse(Target, :calls, :function)
      :ok = :cover.reset(Target)

      call_functions(Source)
      import_path = write_import_for_target(directory)
      :ok = :cover.import(import_path)

      assert :cover.analyse(Target, :calls, :line) == {:ok, expected_lines}
      assert :cover.analyse(Target, :calls, :function) == {:ok, expected_functions}
    end

    test "builds an import that leaves the imported modules unchanged", ctx do
      %{directory: directory} = ctx

      :ok = Coverage.start_cover()
      :ok = Coverage.compile_module(Source)
      :ok = Coverage.compile_module(Target)
      imported_modules = :cover.imported_modules()

      call_functions(Source)
      import_path = write_import_for_target(directory)
      :ok = :cover.import(import_path)

      assert :cover.imported_modules() == imported_modules
    end
  end

  describe "export_module/1" do
    test "keeps nothing and warns when the beam file that cover compiled the module from is gone" do
      :ok = Coverage.start_cover()
      copy_path = Coverage.compile_module_copy(Source)
      File.rm!(copy_path)
      cover_server = Process.whereis(:cover_server)

      log = capture_log(fn -> assert Cover.export_module(Source) == nil end)

      assert log =~ "coverage of #{inspect(Source)}"
      assert log =~ inspect({:file_error, String.to_charlist(copy_path), :enoent})
      assert Process.whereis(:cover_server) == cover_server
    end

    test "keeps nothing and warns when the beam file holds another module" do
      :ok = Coverage.start_cover()
      copy_path = Coverage.compile_module_copy(Source)
      File.cp!(:code.where_is_file(~c"#{Target}.beam"), copy_path)
      cover_server = Process.whereis(:cover_server)

      log = capture_log(fn -> assert Cover.export_module(Source) == nil end)

      assert log =~ "coverage of #{inspect(Source)}"
      assert log =~ inspect({:unusable_beam_file, String.to_charlist(copy_path)})
      assert Process.whereis(:cover_server) == cover_server
    end

    test "keeps nothing and warns when the module is loaded under the cover tag but cover does not know it" do
      :ok = Coverage.start_cover()
      :ok = Coverage.compile_module(Target)
      forget_module(Target)
      on_exit(fn -> Coverage.compile_module(Target) end)
      beam = File.read!(:code.where_is_file(~c"#{Target}.beam"))
      {:module, Target} = :code.load_binary(Target, :cover_compiled, beam)
      cover_server = Process.whereis(:cover_server)

      log = capture_log(fn -> assert Cover.export_module(Target) == nil end)

      assert log =~ "coverage of #{inspect(Target)}"
      assert log =~ inspect({:is_compiled, false})
      assert Process.whereis(:cover_server) == cover_server
    end

    test "keeps nothing and warns when cover compiled the module from Erlang source", ctx do
      %{directory: directory} = ctx

      :ok = Coverage.start_cover()
      source_path = Path.join(directory, "patch_cover_erlang_source.erl")
      File.write!(source_path, "-module(patch_cover_erlang_source).\n")
      on_exit(fn -> forget_module(:patch_cover_erlang_source) end)
      {:ok, :patch_cover_erlang_source} = :cover.compile_module(String.to_charlist(source_path))
      cover_server = Process.whereis(:cover_server)

      log = capture_log(fn -> assert Cover.export_module(:patch_cover_erlang_source) == nil end)

      assert log =~ "coverage of :patch_cover_erlang_source"
      assert log =~ inspect({:unusable_beam_file, String.to_charlist(source_path)})
      assert Process.whereis(:cover_server) == cover_server
    end
  end

  describe "compile_original/2" do
    test "loads the original as plain code and warns when cover cannot compile it" do
      :ok = Coverage.start_cover()
      :ok = Coverage.compile_module(Source)
      cover = Cover.export_module(Source)
      original = Naming.original(Source)
      on_exit(fn -> remove_original(cover) end)
      binary = compile_without_debug_info(original)
      cover_server = Process.whereis(:cover_server)

      log = capture_log(fn -> assert Cover.compile_original(cover, binary) == :ok end)

      assert apply(original, :double, [2]) == 4
      assert :code.which(original) != :cover_compiled
      assert log =~ "coverage of #{inspect(Source)}"
      assert log =~ ":no_abstract_code"
      assert Process.whereis(:cover_server) == cover_server
    end
  end

  describe "export_original/1" do
    test "adds no export and logs nothing for an original loaded as plain code" do
      :ok = Coverage.start_cover()
      :ok = Coverage.compile_module(Source)
      cover = Cover.export_module(Source)
      on_exit(fn -> remove_original(cover) end)
      binary = compile_without_debug_info(Naming.original(Source))
      capture_log(fn -> :ok = Cover.compile_original(cover, binary) end)

      log = capture_log(fn -> assert Cover.export_original(cover) == cover end)

      assert log == ""
    end
  end

  describe "restore_module/1" do
    test "leaves out terms of an unknown shape with a warning and imports the counts" do
      :ok = Coverage.start_cover()
      :ok = Coverage.compile_module(Source)
      call_functions(Source)
      {:ok, expected_counts} = :cover.analyse(Source, :calls, :line)
      cover = Cover.export_module(Source)
      [{Source, export_path}] = cover.exports
      {:ok, terms} = Cover.read_terms(export_path)
      unknown_term = {:unknown_shape, Source}
      :ok = Cover.write_terms(export_path, terms ++ [unknown_term])
      cover_server = Process.whereis(:cover_server)

      log = capture_log(fn -> assert Cover.restore_module(cover) == :ok end)

      assert log =~ "coverage of #{inspect(Source)}"
      assert log =~ inspect([unknown_term])
      assert Process.whereis(:cover_server) == cover_server
      assert :cover.analyse(Source, :calls, :line) == {:ok, expected_counts}
    end

    test "warns about an export it cannot read and an import it cannot write, and keeps the module cover-compiled" do
      :ok = Coverage.start_cover()
      :ok = Coverage.compile_module(Source)
      {:ok, counts_without_calls} = :cover.analyse(Source, :calls, :line)
      call_functions(Source)
      cover = Cover.export_module(Source)
      [{Source, export_path}] = cover.exports
      File.rm_rf!(cover.directory)
      cover_server = Process.whereis(:cover_server)

      log = capture_log(fn -> assert Cover.restore_module(cover) == :ok end)

      assert count_warnings(log, Source) == 2
      assert log =~ export_path
      assert log =~ inspect(:enoent)
      assert Process.whereis(:cover_server) == cover_server
      assert :code.which(Source) == :cover_compiled
      assert :cover.analyse(Source, :calls, :line) == {:ok, counts_without_calls}
    end
  end

  defp call_functions(module) do
    module.double(1)
    module.double(2)
    apply(module, Source, [1])
  end

  defp write_import_for_target(directory) do
    export_path = Path.join(directory, "source.coverdata")
    import_path = Path.join(directory, "target.coverdata")
    :ok = :cover.export(export_path, Source)

    {:ok, terms} = Cover.read_terms(export_path)
    {retargeted, []} = Cover.retarget_terms(terms, Source, Target)
    :ok = Cover.write_terms(import_path, retargeted)

    import_path
  end

  defp compile_without_debug_info(module) do
    forms = [
      {:attribute, 1, :module, module},
      {:attribute, 1, :export, [double: 1]},
      {:function, 1, :double, 1,
       [
         {:clause, 1, [{:var, 1, :Value}], [],
          [{:op, 1, :*, {:var, 1, :Value}, {:integer, 1, 2}}]}
       ]}
    ]

    {:ok, ^module, binary} = :compile.forms(forms)
    binary
  end

  defp remove_original(cover) do
    cover.module
    |> Naming.original()
    |> Patch.Mock.Code.purge()

    File.rm_rf!(cover.directory)
  end

  defp count_warnings(log, module) do
    matches = :binary.matches(log, "coverage of #{inspect(module)}")
    length(matches)
  end

  # Asked about a module that is no longer loaded, cover forgets it.
  defp forget_module(module) do
    Patch.Mock.Code.purge(module)
    false = :cover.is_compiled(module)
  end

  # term_to_binary leaves a binary of distinct bytes uncompressed, so its
  # encoding is the byte count plus six bytes of header.
  defp distinct_bytes(count) do
    for index <- 0..(count - 1), into: <<>>, do: <<rem(index * 151, 256)>>
  end
end
