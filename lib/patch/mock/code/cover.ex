defmodule Patch.Mock.Code.Cover do
  @moduledoc """
  Coverage data of the modules that Patch replaces while `:cover` runs.

  `:cover.export/2` writes the counts of one module to a file and `:cover.import/1` adds the
  counts in such a file to the analysis. Patch moves counts from one module to another module
  with the same functions on the same lines by changing the module name in the terms of an
  export file and importing the result.

  # Patching a Cover-Compiled Module

  While a module is patched, its calls run in the original module. On OTP 27 and later the
  counts gathered before the patch live in the loaded code, which the facade replaces. Patch
  keeps both kinds of counts in four steps.

  1. `export_module/1` exports the counts of the module before the facade is loaded.
  2. `compile_original/2` cover-compiles the original module, so the lines run inside it are
     counted.
  3. `export_original/1` exports the counts of the original before it is purged.
  4. `restore_module/1` cover-compiles the module from its beam file again, which starts it
     with no counts, and imports both exports for it.

  The exports and the beam file of the original live in a temporary directory that
  `restore_module/1` deletes. When the patch fails after the first step, `abandon/1` deletes
  the directory instead, because the module still holds its counts.

  # Failures

  Coverage bookkeeping never fails a patch. When a step fails, Patch logs a warning that names
  the module and the reason and goes on without that step.

  - When the module was not compiled from a beam file that still holds the module, no
    temporary directory for its exports can be created, or its counts cannot be exported, the
    module is patched and restored as if it were not cover-compiled.
  - When the original cannot be cover-compiled, it is loaded as plain code and the lines run
    while the module is patched are not counted.
  - When the module cannot be cover-compiled again at the restore, the caller loads it as plain
    code.
  - Counts that cannot be exported from the original, read back or imported are lost, and terms
    of an unknown shape are left out of the import.

  A call into cover exits when the cover server dies, so every call catches the exit. Cover
  crashes on a beam file that is missing, holds another module or is not a beam file, so such
  files are rejected before the call.

  The files are written and read with `:file` and `:filename`. A test may patch `File`, `Path`
  or `System`, and Patch's own calls must neither get the test's mock values nor show up in the
  history of the patched module.

  # Export File Format

  The format is not documented; this description comes from `cover.erl`. A file is a sequence
  of records. A record is one length byte followed by `:erlang.term_to_binary(term, [:compressed])`.
  A term that takes more than 255 bytes is preceded by a record holding `{:"$size", byte_size}`.

  An export of a module holds these terms.

  - `{:file, module, path}`
  - `{{:bump, module, function, arity, clause, line}, count}`, one per counter
  - On OTP 24 to 26 the clause entry `{module, [{module, function, arity, clause, lines}]}`

  The framing and the bump terms are the same on OTP 24 to 29.
  """

  # Patch does not depend on :tools, so from Elixir 1.15 on the compiler cannot
  # find :cover. Cover is loaded whenever a module is cover-compiled, which is
  # the only case in which these calls run.
  @compile {:no_warn_undefined, :cover}

  require Record

  alias Patch.Mock.Code
  alias Patch.Mock.Naming

  Record.defrecordp(:file_info, Record.extract(:file_info, from_lib: "kernel/include/file.hrl"))

  # A record starts with one byte that holds its length.
  @longest_record_bytes 255

  # System.tmp_dir/0 calls File, so Patch looks for the temporary directory in
  # the same places, in the same order, with Erlang calls.
  @temporary_directory_variables [~c"TMPDIR", ~c"TEMP", ~c"TMP"]
  @default_temporary_directory ~c"/tmp"
  @writable_accesses [:read_write, :write]

  @typedoc """
  A term of a file written by `:cover.export/2`.
  """
  @type export_term :: term()

  @typedoc """
  The reason a file cannot be read or written.
  """
  @type file_error :: :file.posix() | :badarg | :terminated | :system_limit

  @typedoc """
  An export file and the module whose counts it holds.
  """
  @type export :: {source :: module(), path :: Path.t()}

  @typedoc """
  What Patch keeps about a cover-compiled module while the module is patched.

  - `beam_path` - The beam file that cover compiled the module from.
  - `directory` - The temporary directory that holds the exports and the beam file of the
    original.
  - `exports` - The export files written so far.
  - `module` - The patched module.
  """
  @type t :: %__MODULE__{
          beam_path: :file.filename(),
          directory: Path.t(),
          exports: [export()],
          module: module()
        }
  defstruct [:beam_path, :directory, :module, exports: []]

  @doc """
  Tells whether the loaded code of a module was compiled by cover.
  """
  @spec compiled?(module :: module()) :: boolean()
  def compiled?(module) do
    :code.which(module) == :cover_compiled
  end

  @doc """
  Exports the counts of a cover-compiled module to a new temporary directory.

  Call it before the facade is loaded.

  Returns `nil` with a warning when cover did not compile the module from a beam file that
  still holds the module, when the temporary directory cannot be created, or when the export
  fails. The module is then patched and restored as if it were not cover-compiled.
  """
  @spec export_module(module :: module()) :: t() | nil
  def export_module(module) do
    with {:ok, beam_path} <- fetch_beam_path(module),
         {:ok, cover} <- export_to_new_directory(module, beam_path) do
      cover
    else
      {:error, reason} ->
        log_failure(module, "it is not cover-compiled after the patch", reason)
        nil
    end
  end

  @doc """
  Loads the original module from its compiled binary, cover-compiled so that the lines run
  inside it are counted.

  Cover reads the abstract code of a beam file, so the binary must be compiled with
  `:debug_info`. The beam file stays in the temporary directory, because cover reads it again
  when anything cover-compiles the original by its name.

  When cover cannot compile the original, it is loaded as plain code with a warning.
  """
  @spec compile_original(cover :: t(), binary :: binary()) :: :ok | {:error, Code.binary_error()}
  def compile_original(%__MODULE__{} = cover, binary) do
    original = Naming.original(cover.module)

    beam_path =
      cover.directory
      |> :filename.join("#{original}.beam")
      |> String.to_charlist()

    with :ok <- :file.write_file(beam_path, binary),
         :ok <- check_beam_file(original, beam_path),
         {:ok, ^original} <- call_cover(fn -> :cover.compile_beam(beam_path) end) do
      :ok
    else
      {:error, reason} ->
        log_failure(cover.module, "the lines run while it is patched are not counted", reason)
        load_plain_binary(original, binary)
    end
  end

  @doc """
  Exports the counts of the original module if it is cover-compiled.

  Call it before the original is purged. Returns the cover data with the export added, or
  unchanged with a warning when the export fails.
  """
  @spec export_original(cover :: t()) :: t()
  def export_original(%__MODULE__{} = cover) do
    original = Naming.original(cover.module)

    if compiled?(original) do
      case export_counts(cover, original) do
        {:ok, cover} ->
          cover

        {:error, reason} ->
          log_failure(cover.module, "the lines run while it was patched are not counted", reason)
          cover
      end
    else
      cover
    end
  end

  @doc """
  Loads the cover-compiled module again with all its counts, once Patch has purged the modules
  it generated.

  Cover forgets the purged original and compiles the module from its beam file, which clears the
  counts of the module. Then the exports are imported for the module, and the temporary
  directory is deleted.

  Returns an error when the module cannot be cover-compiled again. The warning is logged
  already, and the caller loads the module as plain code.
  """
  @spec restore_module(cover :: t()) :: :ok | {:error, term()}
  def restore_module(%__MODULE__{} = cover) do
    original = Naming.original(cover.module)
    :ok = forget_module(original)

    result =
      with :ok <- compile_module(cover) do
        import_counts(cover)
      end

    :ok = delete_directory(cover.directory)
    result
  end

  @doc """
  Cleans up after a patch that failed once `export_module/1` had exported the counts.

  The module was never replaced and still holds its counts, so nothing is imported: the
  temporary directory is deleted with the export. Purge the original before the call, so that
  cover forgets it.
  """
  @spec abandon(cover :: t()) :: :ok
  def abandon(%__MODULE__{} = cover) do
    original = Naming.original(cover.module)
    :ok = forget_module(original)

    delete_directory(cover.directory)
  end

  @doc """
  Reads the terms of a file written by `:cover.export/2`, in file order.
  """
  @spec read_terms(path :: Path.t()) :: {:ok, [export_term()]} | {:error, file_error()}
  def read_terms(path) do
    with {:ok, binary} <- :file.read_file(path) do
      {:ok, decode_terms(binary, [])}
    end
  end

  @doc """
  Builds the terms that import the counts of the `source` module into the `target` module.

  The `target` must have the functions of the `source` on the same lines.

  Bump keys and clause entries of the `source` get the `target` in their module positions. A
  function whose name equals the name of the `source` keeps its name.

  `{:file, _, _}` terms are dropped. An import without them adds the counts and does not record
  the `target` as imported, so a later `:cover.compile_beam/1` of the `target` does not warn
  that it deletes imported data.

  Every other term is returned as unknown, so the caller can report it. Unknown terms must not
  be imported: the import in `cover.erl` has no clause for them and crashes the cover server on
  most of them.
  """
  @spec retarget_terms(terms :: [export_term()], source :: module(), target :: module()) ::
          {retargeted :: [export_term()], unknown :: [export_term()]}
  def retarget_terms(terms, source, target) do
    classified = Enum.map(terms, &retarget_term(&1, source, target))
    retargeted = for {:retargeted, term} <- classified, do: term
    unknown = for {:unknown, term} <- classified, do: term

    {retargeted, unknown}
  end

  @doc """
  Writes terms to a file in the format that `:cover.import/1` reads.
  """
  @spec write_terms(path :: Path.t(), terms :: [export_term()]) :: :ok | {:error, file_error()}
  def write_terms(path, terms) do
    records = Enum.map(terms, &encode_term/1)
    :file.write_file(path, records)
  end

  ## Private

  @spec call_cover(request :: (-> result)) :: result | {:error, {:cover_exited, term()}}
        when result: term()
  defp call_cover(request) do
    # A call into cover exits when the cover server dies.
    try do
      request.()
    catch
      :exit, reason ->
        {:error, {:cover_exited, reason}}
    end
  end

  @spec check_beam_file(module :: module(), path :: :file.filename()) :: :ok | {:error, term()}
  defp check_beam_file(module, path) do
    # Cover crashes on a beam file that is missing, holds another module or is not a beam file.
    # It returns an error for a beam file without abstract code, so checking the module name is
    # enough. Reading the name does not build the abstract code from the debug info.
    with ~c".beam" <- :filename.extension(path),
         info when is_list(info) <- :beam_lib.info(path),
         {:ok, ^module} <- Keyword.fetch(info, :module) do
      :ok
    else
      {:error, :beam_lib, reason} ->
        {:error, reason}

      _unusable ->
        {:error, {:unusable_beam_file, path}}
    end
  end

  @spec compile_module(cover :: t()) :: :ok | {:error, term()}
  defp compile_module(%__MODULE__{module: module} = cover) do
    with :ok <- check_beam_file(module, cover.beam_path),
         {:ok, ^module} <- call_cover(fn -> :cover.compile_beam(cover.beam_path) end) do
      :ok
    else
      {:error, reason} = error ->
        # The module is purged, so cover forgets it instead of failing to collect
        # its counts at the next analysis.
        :ok = forget_module(module)
        log_failure(module, "it is not cover-compiled after the patch", reason)
        error
    end
  end

  @spec create_directory() :: {:ok, Path.t()} | {:error, term()}
  defp create_directory() do
    # Partitioned test runs share the temporary directory, so the name carries the OS process.
    unique_name = "patch-cover-#{:os.getpid()}-#{:erlang.unique_integer([:positive])}"

    with {:ok, temporary_directory} <- fetch_temporary_directory() do
      directory = :filename.join(temporary_directory, unique_name)

      case :file.make_dir(directory) do
        :ok ->
          {:ok, directory}

        {:error, reason} ->
          {:error, {:make_dir, directory, reason}}
      end
    end
  end

  @spec decode_terms(binary :: binary(), terms :: [export_term()]) :: [export_term()]
  defp decode_terms(<<>>, terms) do
    Enum.reverse(terms)
  end

  defp decode_terms(<<size, record::binary-size(size), rest::binary>>, terms) do
    case :erlang.binary_to_term(record) do
      {:"$size", long_size} ->
        {long_record, rest} = :erlang.split_binary(rest, long_size)
        decode_terms(rest, [:erlang.binary_to_term(long_record) | terms])

      term ->
        decode_terms(rest, [term | terms])
    end
  end

  @spec delete_directory(directory :: Path.t()) :: :ok
  defp delete_directory(directory) do
    # The directory is gone when something else removed it during the patch. One
    # that cannot be deleted is left in the temporary directory.
    _ = :file.del_dir_r(directory)
    :ok
  end

  @spec encode_term(term :: export_term()) :: iodata()
  defp encode_term(term) do
    record = :erlang.term_to_binary(term, [:compressed])
    frame_record(record)
  end

  @spec export_counts(cover :: t(), source :: module()) :: {:ok, t()} | {:error, term()}
  defp export_counts(%__MODULE__{} = cover, source) do
    path = :filename.join(cover.directory, "#{source}.coverdata")

    with :ok <- call_cover(fn -> :cover.export(path, source) end) do
      {:ok, %__MODULE__{cover | exports: [{source, path} | cover.exports]}}
    end
  end

  @spec export_to_new_directory(module :: module(), beam_path :: :file.filename()) ::
          {:ok, t()} | {:error, term()}
  defp export_to_new_directory(module, beam_path) do
    with {:ok, directory} <- create_directory() do
      cover = %__MODULE__{beam_path: beam_path, directory: directory, module: module}

      case export_counts(cover, module) do
        {:ok, cover} ->
          {:ok, cover}

        {:error, _reason} = error ->
          :ok = delete_directory(directory)
          error
      end
    end
  end

  @spec fetch_beam_path(module :: module()) :: {:ok, :file.filename()} | {:error, term()}
  defp fetch_beam_path(module) do
    case call_cover(fn -> :cover.is_compiled(module) end) do
      {:file, path} ->
        with :ok <- check_beam_file(module, path), do: {:ok, path}

      not_compiled ->
        {:error, {:is_compiled, not_compiled}}
    end
  end

  @spec fetch_temporary_directory() ::
          {:ok, :file.filename()} | {:error, :no_writable_temporary_directory}
  defp fetch_temporary_directory() do
    case Enum.find(list_temporary_directories(), &writable_directory?/1) do
      nil ->
        {:error, :no_writable_temporary_directory}

      directory ->
        {:ok, directory}
    end
  end

  @spec forget_module(module :: module()) :: :ok
  defp forget_module(module) do
    # Asked about a module that is no longer loaded, cover forgets it. If the
    # cover server is gone, there is nothing left to forget.
    _ = call_cover(fn -> :cover.is_compiled(module) end)
    :ok
  end

  @spec frame_record(record :: binary()) :: iodata()
  defp frame_record(record) when byte_size(record) > @longest_record_bytes do
    size_record = :erlang.term_to_binary({:"$size", byte_size(record)})
    [byte_size(size_record), size_record, record]
  end

  defp frame_record(record) do
    [byte_size(record), record]
  end

  @spec import_counts(cover :: t()) :: :ok
  defp import_counts(%__MODULE__{module: module} = cover) do
    counts = Enum.flat_map(cover.exports, &read_counts(module, &1))
    import_path = :filename.join(cover.directory, "import.coverdata")

    with :ok <- write_terms(import_path, counts),
         :ok <- call_cover(fn -> :cover.import(import_path) end) do
      :ok
    else
      {:error, reason} ->
        log_failure(module, "its counts are lost", reason)
    end
  end

  @spec list_temporary_directories() :: [:file.filename()]
  defp list_temporary_directories() do
    environment_directories =
      @temporary_directory_variables
      |> Enum.map(&:os.getenv/1)
      |> Enum.filter(&is_list/1)

    environment_directories ++ [@default_temporary_directory | list_working_directory()]
  end

  @spec list_working_directory() :: [:file.filename()]
  defp list_working_directory() do
    case :file.get_cwd() do
      {:ok, directory} ->
        [directory]

      {:error, _reason} ->
        []
    end
  end

  @spec load_plain_binary(module :: module(), binary :: binary()) ::
          :ok | {:error, Code.binary_error()}
  defp load_plain_binary(module, binary) do
    with {:module, ^module} <- :code.load_binary(module, ~c"", binary) do
      :ok
    end
  end

  @spec log_failure(module :: module(), consequence :: String.t(), reason :: term()) :: :ok
  defp log_failure(module, consequence, reason) do
    # Logger.warning/1 needs Elixir 1.11, and a test may patch Logger.
    :logger.warning(
      "Patch could not keep the coverage of #{inspect(module)}: #{consequence}. " <>
        "Reason: #{inspect(reason)}"
    )
  end

  @spec log_unknown_terms(module :: module(), unknown :: [export_term()]) :: :ok
  defp log_unknown_terms(_module, []) do
    :ok
  end

  defp log_unknown_terms(module, unknown) do
    log_failure(module, "terms of an unknown shape are left out of its counts", unknown)
  end

  @spec read_counts(module :: module(), export :: export()) :: [export_term()]
  defp read_counts(module, {source, path}) do
    case read_terms(path) do
      {:ok, terms} ->
        # Terms of unknown shapes are left out, because importing them crashes
        # the cover server.
        {counts, unknown} = retarget_terms(terms, source, module)
        :ok = log_unknown_terms(module, unknown)
        counts

      {:error, reason} ->
        log_failure(module, "the counts in #{path} are lost", reason)
        []
    end
  end

  @spec retarget_term(term :: export_term(), source :: module(), target :: module()) ::
          :dropped | {:retargeted, export_term()} | {:unknown, export_term()}
  defp retarget_term({:file, _module, _path}, _source, _target) do
    :dropped
  end

  defp retarget_term({{:bump, source, function, arity, clause, line}, count}, source, target) do
    {:retargeted, {{:bump, target, function, arity, clause, line}, count}}
  end

  defp retarget_term({source, clauses} = term, source, target) when is_list(clauses) do
    if Enum.all?(clauses, &match?({^source, _function, _arity, _clause, _lines}, &1)) do
      retargeted_clauses = Enum.map(clauses, &put_elem(&1, 0, target))
      {:retargeted, {target, retargeted_clauses}}
    else
      {:unknown, term}
    end
  end

  defp retarget_term(term, _source, _target) do
    {:unknown, term}
  end

  @spec writable_directory?(path :: :file.filename()) :: boolean()
  defp writable_directory?(path) do
    case :file.read_file_info(path) do
      {:ok, file_info(type: :directory, access: access)} ->
        access in @writable_accesses

      _not_a_directory ->
        false
    end
  end
end
