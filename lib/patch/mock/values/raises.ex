defmodule Patch.Mock.Values.Raises do
  @type t :: %__MODULE__{
          exception: module(),
          attributes: Keyword.t()
        }
  defstruct [:exception, :attributes]

  @spec advance(raises :: t()) :: t()
  def advance(%__MODULE__{} = raises) do
    raises
  end

  @spec new(message :: String.t()) :: t()
  def new(message) do
    new(RuntimeError, message: message)
  end

  @spec new(exception :: module(), attributes :: Keyword.t()) :: t()
  def new(exception, attributes) do
    %__MODULE__{exception: exception, attributes: attributes}
  end

  @spec next(raises :: t(), arguments :: [term()]) :: none()
  def next(%__MODULE__{} = raises, _arguments) do
    raise raises.exception, raises.attributes
  end
end
