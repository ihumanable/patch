defmodule Patch.Mock.History.Tagged do
  alias Patch.Mock.History

  @type tag :: boolean()
  @type entry :: {tag(), History.entry()}
  @type t :: [entry()]

  @doc """
  Determine if any of the entries have been tagged in the affirmative
  """
  @spec any?(tagged :: t()) :: boolean()
  def any?(tagged) do
    Enum.any?(tagged, &tag/1)
  end

  @doc """
  Calculates the count of entries that have been tagged in the affirmative
  """
  @spec count(tagged :: t()) :: non_neg_integer()
  def count(tagged) do
    tagged
    |> Enum.filter(&tag/1)
    |> Enum.count()
  end

  @doc """
  Returns the first entry that was tagged in the affirmative
  """
  @spec first(tagged :: t()) :: {:ok, History.entry()} | false
  def first(tagged) do
    Enum.find_value(tagged, fn
      {true, call} ->
        {:ok, call}

      _ ->
        false
    end)
  end

  def format(entries, module) do
    entries
    |> Enum.reverse()
    |> Enum.with_index(1)
    |> Enum.map(fn {{tag, {function, arguments}}, i} ->
      marker =
        if tag do
          "* "
        else
          "  "
        end

      "#{marker}#{i}. #{inspect(module)}.#{function}(#{format_arguments(arguments)})"
    end)
    |> case do
      [] ->
        "  [No Calls Received]"

      calls ->
        Enum.join(calls, "\n")
    end
  end

  @doc """
  Construct a new Tagged History from a History and a Call.

  Every entry in the History will be tagged with either `true` if the entry
  matches the provided call or `false` if the entry does not match.
  """
  @spec for_call(history :: Macro.t(), call :: Macro.t()) :: Macro.t()
  defmacro for_call(history, call) do
    {_, function, pattern} = Macro.decompose_call(call)

    quote do
      unquote(history)
      |> Patch.Mock.History.entries(:desc)
      |> Enum.map(fn
        {unquote(function), arguments} = call ->
          {Patch.Macro.match?(unquote(pattern), arguments), call}

        call ->
          {false, call}
      end)
    end
  end

  @doc """
  Construct a new Tagged History from a History and a Function Name.

  Every entry in the History will be tagged with either `true` if the entry
  matches the provided Function Name or `false` if the entry does not match.
  """
  @spec for_function(history :: History.t(), name :: History.name()) :: t()
  def for_function(%History{} = history, name) do
    history
    |> History.entries(:desc)
    |> Enum.map(fn
      {^name, _} = call ->
        {true, call}

      call ->
        {false, call}
    end)
  end

  @doc """
  Returns the tag for the given tagged entry
  """
  @spec tag(entry :: entry()) :: tag()
  def tag({tag, _}) do
    tag
  end

  ## Private

  @spec format_arguments(arguments :: [term()]) :: String.t()
  defp format_arguments(arguments) do
    arguments
    |> Enum.map(&Kernel.inspect/1)
    |> Enum.join(", ")
  end
end
