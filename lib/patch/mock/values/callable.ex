defmodule Patch.Mock.Values.Callable do
  alias Patch.Apply

  @type dispatch_mode :: :apply | :list
  @type evaluate_mode :: :passthrough | :strict

  @type dispatch_option :: {:dispatch, dispatch_mode()}
  @type evaluate_option :: {:evaluate, evaluate_mode()}

  @type option :: dispatch_option() | evaluate_option()

  @type t :: %__MODULE__{
          dispatch: dispatch_mode(),
          evaluate: evaluate_mode(),
          target: function()
        }
  defstruct [:dispatch, :evaluate, :target]

  @spec advance(callable :: t()) :: t()
  def advance(callable) do
    callable
  end

  @spec new(target :: function(), options :: [option()]) :: t()
  def new(target, options \\ []) do
    options = validate_options!(options)

    %__MODULE__{
      dispatch: options[:dispatch],
      evaluate: options[:evaluate],
      target: target
    }
  end

  @spec next(callable :: t(), arguments :: [term()]) :: {:ok, t(), term()} | :error
  def next(%__MODULE__{} = callable, arguments) do
    arguments
    |> dispatch(callable)
    |> evaluate(callable)
  end

  ## Private

  @spec dispatch(arguments :: [term()], callable :: t()) :: [term()]
  defp dispatch(arguments, %__MODULE__{dispatch: :apply}) do
    arguments
  end

  defp dispatch(arguments, %__MODULE__{dispatch: :list}) do
    [arguments]
  end

  @spec evaluate(arguments :: [term()], callable :: t()) :: {:ok, t(), term()} | :error
  defp evaluate(arguments, %__MODULE__{evaluate: :passthrough} = callable) do
    with {:ok, result} <- Apply.safe(callable.target, arguments) do
      {:ok, callable, result}
    end
  end

  defp evaluate(arguments, %__MODULE__{evaluate: :strict} = callable) do
    {:ok, callable, apply(callable.target, arguments)}
  end



  @spec validate_options!(options :: [option()]) :: [option()]
  defp validate_options!(options) do
    {dispatch, options} = Keyword.pop(options, :dispatch, :apply)
    {evaluate, options} = Keyword.pop(options, :evaluate, :passthrough)

    unless Enum.empty?(options) do
      unexpected_options =
        options
        |> Keyword.keys()
        |> Enum.map(&inspect/1)
        |> Enum.join("  \n - ")


      message = """
      \n
      Callable contains unexpected options:

        #{unexpected_options}
      """

      raise Patch.ConfigurationError, message: message
    end

    unless dispatch in [:apply, :list] do
      message = "Invalid :dispatch option #{inspect(dispatch)}.  Must be one of [:apply, :list]"
      raise Patch.ConfigurationError, message: message
    end

    unless evaluate in [:passthrough, :strict] do
      message =
        "Invalid :evaluate option #{inspect(evaluate)}.  Must be one of [:passthrough, :strict]"
      raise Patch.ConfigurationError, message: message
    end

    [dispatch: dispatch, evaluate: evaluate]
  end
end
