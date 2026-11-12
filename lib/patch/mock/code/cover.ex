defmodule Patch.Mock.Code.Cover do
  @moduledoc """
  Coverage data of the modules that Patch replaces while `:cover` runs.

  `:cover.export/2` writes the counts of one module to a file and `:cover.import/1` adds the
  counts in such a file to the analysis. Patch moves counts from one module to another module
  with the same functions on the same lines by changing the module name in the terms of an
  export file and importing the result.

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

  # A record starts with one byte that holds its length.
  @longest_record_bytes 255

  @typedoc """
  A term of a file written by `:cover.export/2`.
  """
  @type export_term :: term()

  @typedoc """
  The reason a file cannot be read or written.
  """
  @type file_error :: :file.posix() | :badarg | :terminated | :system_limit

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

  @spec encode_term(term :: export_term()) :: iodata()
  defp encode_term(term) do
    record = :erlang.term_to_binary(term, [:compressed])
    frame_record(record)
  end

  @spec frame_record(record :: binary()) :: iodata()
  defp frame_record(record) when byte_size(record) > @longest_record_bytes do
    size_record = :erlang.term_to_binary({:"$size", byte_size(record)})
    [byte_size(size_record), size_record, record]
  end

  defp frame_record(record) do
    [byte_size(record), record]
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
end
