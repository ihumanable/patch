defmodule Patch.Mock.History do
  @type name :: atom()
  @type arguments :: [term()]
  @type entry :: {name(), arguments()}

  @type t :: %__MODULE__{
    count: non_neg_integer(),
    entries: [entry()],
    limit: non_neg_integer() | :infinity
  }
  defstruct [
    count: 0,
    entries: [],
    limit: :infinity
  ]

  def new(limit \\ :infinity) do
    %__MODULE__{limit: limit}
  end

  def entries(history, sorting \\ :asc)

  def entries(%__MODULE__{} = history, :asc) do
    Enum.reverse(history.entries)
  end

  def entries(%__MODULE__{} = history, :desc) do
    history.entries
  end

  def put(%__MODULE__{limit: 0} = history, _name, _arguments) do
    # When the limit is 0, no-op.
    history
  end

  def put(%__MODULE__{limit: 1} = history, name, arguments) do
    # When the limit is 1 just set the entries directly
    %__MODULE__{history | count: 1, entries: [{name, arguments}]}
  end

  def put(%__MODULE__{limit: :infinity} = history, name, arguments) do
    # When the history is infinite just keep appending.
    %__MODULE__{history | count: history.count + 1, entries: [{name, arguments} | history.entries]}
  end

  def put(%__MODULE__{limit: limit, count: count} = history, name, arguments) when count < limit do
    # When there is still slack capacity in the history, do a simple append.
    %__MODULE__{history | count: history.count + 1, entries: [{name, arguments} | history.entries]}
  end

  def put(%__MODULE__{} = history, name, arguments) do
    # Buffer is bounded and out of slack capacity.
    entries = Enum.take([{name, arguments} | history.entries], history.limit)
    %__MODULE__{history | entries: entries}
  end
end
