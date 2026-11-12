defmodule Patch.Test.Unit.Patch.Mock.Code.CoverTest do
  use ExUnit.Case, async: false

  alias Patch.Mock.Code.Cover
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

  # term_to_binary leaves a binary of distinct bytes uncompressed, so its
  # encoding is the byte count plus six bytes of header.
  defp distinct_bytes(count) do
    for index <- 0..(count - 1), into: <<>>, do: <<rem(index * 151, 256)>>
  end
end
