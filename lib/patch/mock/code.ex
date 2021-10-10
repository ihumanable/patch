defmodule Patch.Mock.Code do
  @moduledoc """
  Patch mocks out modules by generating mock modules and recompiling them for a `target` module.

  Patch's approach to mocking a module provides some powerful affordances.

  - Private functions can be mocked.
  - Internal function calls are effected by mocks regardless of the function's visibility without
    having to change the way code is written.
  - Private functions can be optionally exposed in the facade to make it possible to test a
    private function directly without changing its visibility in code.

  # Mocking Strategy

  There are 4 logical modules and 1 GenServer that are involved when mocking a module.

  The 4 logical modules:

  - `target` - The module to be mocked.
  - `facade` - The `target` module is replaced by a `facade` module that intercepts all external
               calls and redirects them to the `delegate` module.
  - `original` - The `target` module is preserved as the `original` module, with the important
                 transformation that all local calls are redirected to the `delegate` module.
  - `delegate` - This module is responsible for checking with the `server` to see if a call is
                 mocked and should be intercepted.  If so, the mock value is returned, otherwise
                 the `original` function is called.

  Each `target` module has an associated GenServer, a `Patch.Mock.Server` that has keeps state
  about the history of function calls and holds the mock data to be returned on interception.  See
  `Patch.Mock.Server` for more information.

  ## Example Target Module

  To better understand how Patch works, consider the following example module.

  ```elixir
  defmodule Example do
    def public_function(argument_1, argument_2) do
      {:public, private_function(argument_1, argument_2)}
    end

    defp private_function(argument_1, argument_2) do
      {:private, argument_1, argument_2}
    end
  end
  ```

  ### `facade` module

  The `facade` module is automatically generated based off the exports of the `target` module.
  It takes on the name of the `provided` module.

  For each exported function, a function is generated in the `facade` module that calls the
  `delegate` module.

  ```elixir
  defmodule Example do
    def public_function(argument_1, argument_2) do
      Patch.Mock.Delegate.For.Example.public_function(argument_1, argument_2)
    end
  end
  ```

  ### `delegate` module

  The `delegate` module is automatically generated based off all the functions of the `target`
  module.  It takes on a name based off the `target` module, see `Patch.Mock.Naming.delegate/1`.

  For each function, a function is generated in the `delegate` module that calls
  `Patch.Mock.Server.delegate/3` delegating to the server named for the `target` module, see
  `Patch.Mock.Naming.server/1`.

  ```elixir
  defmodule Patch.Mock.Delegate.For.Example do
    def public_function(argument_1, argument_2) do
      Patch.Mock.Server.delegate(
        Patch.Mock.Server.For.Example,
        :public_function,
        [argument_1, argument_2]
      )
    end

    def private_function(argument_1, argument_2) do
      Patch.Mock.Server.delegate(
        Patch.Mock.Server.For.Example,
        :private_function,
        [argument_1, argument_2]
      )
    end
  end
  ```

  ### `original` module

  The `original` module takes on a name based off the `provided` module, see
  `Patch.Mock.Naming.original/1`.

  The code is transformed in the following ways.
    - All local calls are converted into remote calls to the `delegate` module.
    - All functions are exported

  ```elixir
  defmodule Patch.Mock.Original.For.Example do
    def public_function(argument_1, argument_2) do
      {:public, Patch.Mock.Delegate.For.Example.private_function(argument_1, argument_2)}
    end

    def private_function(argument_1, argument_2) do
      {:private, argument_1, argument_2}
    end
  end
  ```

  ## External Function Calls

  First, let's examine how calls from outside the module are treated.

  ### Public Function Calls

  Code calling `Example.public_function/2` has the following call flow.

  ```
  [Caller] -> facade -> delegate -> serve` -> mocked? -> yes   (Intercepted)
           [Mock Value] <----------------------------|----'
                                                      -> no -> original   (Run Original Code)
           [Original Value] <--------------------------------------'
  ```

  Calling a public funtion will either return the mocked value if it exists, or fall back to
  calling the original function.

  ### Private Function Calls

  Code calling `Example.private_function/2` has the following call flow.

  ```
  [Caller] --------------------------> `facade`
           [UndefinedFunctionError] <------'
  ```

  Calling a private function continues to be an error from the external caller's point of view.

  The `expose` option does allow the facade to expose private functions, in those cases the call
  flow just follows the public call flow.

  ## Internal Calls

  Next, let's examine how calls from outside the module are treated.

  ### Public Function Calls

  Code in the `original` module calling public functions have their code transformed to call the
  `delegate` module.

  ```
  original -> delegate -> server -> mocked? -> yes   (Intercepted)
           [Mock Value] <------------------|----'
                                            -> no -> original   (Run Original Code)
           [Original Value] <----------------------------'
  ```

  Since the call is redirected to the `delegate`, calling a public funtion will either return the
  mocked value if it exists, or fall back to calling the original function.

  ### Private Function Call Flow

  Code in the `original` module calling private functions have their code transformed to call the
  `delegate` module

  ```
  original -> delegate -> server -> mocked? -> yes   (Intercepted)
           [Mock Value] <------------------|----'
                                            -> no -> original   (Run Original Code)
           [Original Value] <----------------------------'
  ```

  Since the call is redirected to the `delegate`, calling a private funtion will either return the
  mocked value if it exists, or fall back to calling the original function.

  ## Code Generation

  For additional details on how Code Generation works, see the `Patch.Mock.Code.Generate` module.
  """

  alias Patch.Mock.Code.Generate
  alias Patch.Mock.Code.Transform

  @type form :: term()
  @type exports :: Keyword.t(arity())

  @typedoc """
  The expose option controls if any private functions should be exposed in the `facade` module.

  The default is to leave private functions as private, but the caller can provide either the atom
  `:all` which will expose all private functions or can provide an `t:exports/0` to define which
  private functions should be exposed.
  """
  @type expose_option :: {:expose, Transform.exposes()}

  @typedoc """
  Sum-type of all valid options
  """
  @type option :: expose_option()


  @spec abstract_forms(module :: module) ::
          {:ok, [form()]}
          | {:error, :abstract_forms_unavailable}
          | {:error, :chunk_too_big}
          | {:error, :file_error}
          | {:error, :invalid_beam_file}
          | {:error, :key_missing_or_invalid}
          | {:error, :missing_backend}
          | {:error, :missing_chunk}
          | {:error, :not_a_beam_file}
          | {:error, :unknown_chunk}
  def abstract_forms(module) do
    with :ok <- ensure_loaded(module),
         {:ok, binary} <- binary(module) do
      case :beam_lib.chunks(binary, [:abstract_code]) do
        {:ok, {_, [abstract_code: {:raw_abstract_v1, abstract_forms}]}} ->
          {:ok, abstract_forms}

        {:error, :beam_lib, details} ->
          reason = elem(details, 0)
          {:error, reason}

        _ ->
          {:error, :abstract_forms_unavailable}
      end
    end
  end

  @spec compile([form()]) :: :ok | {:error, {:abstract_forms_invalid, [form()], term()}}
  def compile(abstract_forms) do
    case :compile.forms(abstract_forms, [:return_errors]) do
      {:ok, module, binary} ->
        load_binary(module, binary)

      {:ok, module, binary, _} ->
        load_binary(module, binary)

      errors ->
        {:error, {:abstract_forms_invalid, abstract_forms, errors}}
    end
  end

  @doc """
  Mocks a module by generating a set of modules based on the `target` module.
  """
  @spec mock(module :: module(), options :: [option()]) :: :ok | {:error, term}
  def mock(module, options \\ []) do
    exposes = options[:exposes] || :none

    with {:ok, abstract_forms} <- abstract_forms(module),
         delegate_forms = Generate.delegate(abstract_forms, module),
         facade_forms = Generate.facade(abstract_forms, module, exposes),
         original_forms = Generate.original(abstract_forms, module),
         :ok <- compile(delegate_forms),
         :ok <- compile(original_forms),
         :ok <- compile(facade_forms) do
      :ok
    end
  end

  ## Private

  @spec binary(module :: module()) :: {:ok, binary()} | {:error, :binary_unavailable}
  defp binary(module) do
    case :code.get_object_code(module) do
      {^module, binary, _} ->
        {:ok, binary}

      :error ->
        {:error, :binary_unavailable}
    end
  end

  @spec ensure_loaded(module :: module()) ::
          :ok
          | {:error, :embedded}
          | {:error, :badfile}
          | {:error, :nofile}
          | {:error, :on_load_failure}
  defp ensure_loaded(module) do
    with {:module, ^module} <- Code.ensure_loaded(module) do
      :ok
    end
  end

  @spec load_binary(module :: module(), binary :: binary()) ::
          :ok
          | {:error, :badfile}
          | {:error, :nofile}
          | {:error, :not_purged}
          | {:error, :on_load_failure}
          | {:error, :sticky_directory}
  defp load_binary(module, binary) do
    with {:module, ^module} <- :code.load_binary(module, '', binary) do
      :ok
    end
  end
end
