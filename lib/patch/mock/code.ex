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
    mocked and should be intercepted.  If so, the mock value is returned, otherwise the `original`
    function is called.

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

  ```text
  [Caller] -> facade -> delegate -> server -> mocked? -> yes   (Intercepted)
           [Mock Value] <----------------------------|----'
                                                      -> no -> original   (Run Original Code)
           [Original Value] <--------------------------------------'
  ```

  Calling a public funtion will either return the mocked value if it exists, or fall back to
  calling the original function.

  ### Private Function Calls

  Code calling `Example.private_function/2` has the following call flow.

  ```text
  [Caller] --------------------------> facade
           [UndefinedFunctionError] <-----'
  ```

  Calling a private function continues to be an error from the external caller's point of view.

  The `expose` option does allow the facade to expose private functions, in those cases the call
  flow just follows the public call flow.

  ## Internal Calls

  Next, let's examine how calls from outside the module are treated.

  ### Public Function Calls

  Code in the `original` module calling public functions have their code transformed to call the
  `delegate` module.

  ```text
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

  ```text
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

  alias Patch.Mock
  alias Patch.Mock.Code.Generate
  alias Patch.Mock.Code.Query
  alias Patch.Mock.Code.Unit

  @type chunk_error ::
          :chunk_too_big
          | :file_error
          | :invalid_beam_file
          | :key_missing_or_invalid
          | :missing_backend
          | :missing_chunk
          | :not_a_beam_file
          | :unknown_chunk

  @type compiler_option :: term()

  @type form :: term()
  @type export_classification :: :builtin | :generated | :normal
  @type exports :: Keyword.t(arity())

  @typedoc """
  Sum-type of all valid options
  """
  @type option :: Mock.exposes_option()

  @spec abstract_forms(module :: module) ::
          {:ok, [form()]}
          | {:error, :abstract_forms_unavailable}
          | {:error, chunk_error()}
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

  @spec attributes(module :: module()) :: {:ok, Keyword.t()} | {:error, :attributes_unavailable}
  def attributes(module) do
    with :ok <- ensure_loaded(module) do
      try do
        Keyword.get(module.module_info(), :attributes, [])
      catch
        _, _ ->
          {:error, :attributes_unavailable}
      end
    end
  end

  @doc """
  Classifies an exported mfa into one of the following classifications

  - :builtin - Export is a BIF.
  - :generated - Export is a generated function.
  - :normal - Export is a user defined function.
  """
  @spec classify_export(module :: module(), function :: atom(), arity :: arity()) :: export_classification()
  def classify_export(_, :module_info, 0), do: :generated
  def classify_export(_, :module_info, 1), do: :generated
  def classify_export(module, function, arity) do
    if :erlang.is_builtin(module, function, arity) do
      :builtin
    else
      :normal
    end
  end


  @spec compile(abstract_forms :: [form()], compiler_options :: [compiler_option()]) ::
          :ok
          | {:error, {:abstract_forms_invalid, [form()], term()}}
  def compile(abstract_forms, compiler_options \\ []) do
    case :compile.forms(abstract_forms, [:return_errors | compiler_options]) do
      {:ok, module, binary} ->
        load_binary(module, binary)

      {:ok, module, binary, _} ->
        load_binary(module, binary)

      errors ->
        {:error, {:abstract_forms_invalid, abstract_forms, errors}}
    end
  end

  @spec compiler_options(module :: module()) ::
          {:ok, [compiler_option()]}
          | {:error, :compiler_options_unavailable}
          | {:error, chunk_error()}
  def compiler_options(module) do
    with :ok <- ensure_loaded(module),
         {:ok, binary} <- binary(module) do
      case :beam_lib.chunks(binary, [:compile_info]) do
        {:ok, {_, [compile_info: info]}} ->
          filtered_options =
            case Keyword.fetch(info, :options) do
              {:ok, options} ->
                filter_compiler_options(options)

              :error ->
                []
            end

          {:ok, filtered_options}

        {:error, :beam_lib, details} ->
          reason = elem(details, 0)
          {:error, reason}

        _ ->
          {:error, :compiler_options_unavailable}
      end
    end
  end

  @spec exports(abstract_forms :: [form()], module :: module(), exposes :: Mock.exposes()) :: exports()
  def exports(abstract_forms, module, :public) do
    exports = Query.exports(abstract_forms)
    filter_exports(module, exports, :normal)
  end

  def exports(abstract_forms, module, :all) do
    exports = Query.functions(abstract_forms)
    filter_exports(module, exports, :normal)
  end

  def exports(abstract_forms, module, exposes) do
    exports = exposes ++ Query.exports(abstract_forms)
    filter_exports(module, exports, :normal)
  end

  @doc """
  Given a module and a list of exports filters the list of exports to those that
  have the given classification.

  See `classify_export/3` for information about export classification
  """
  @spec filter_exports(module :: module, exports :: exports(), classification :: export_classification()) :: exports()
  def filter_exports(module, exports, classification) do
    Enum.filter(exports, fn {name, arity} ->
      classify_export(module, name, arity) == classification
    end)
  end

  @doc """
  Mocks a module by generating a set of modules based on the `target` module.

  The `target` module's unchanged abstract_form is returned on success.
  """
  @spec module(module :: module(), options :: [option()]) :: {:ok, Unit.t()} | {:error, term}
  def module(module, options \\ []) do
    exposes = options[:exposes] || :public

    with {:ok, compiler_options} <- compiler_options(module),
         {:ok, sticky?} <- unstick_module(module),
         {:ok, abstract_forms} <- abstract_forms(module),
         local_exports = exports(abstract_forms, module, :all),
         remote_exports = exports(abstract_forms, module, exposes),
         delegate_forms = Generate.delegate(abstract_forms, module, local_exports),
         facade_forms = Generate.facade(abstract_forms, module, remote_exports),
         original_forms = Generate.original(abstract_forms, module, local_exports),
         :ok <- compile(delegate_forms),
         :ok <- compile(original_forms, compiler_options),
         :ok <- compile(facade_forms) do
      unit = %Unit{
        abstract_forms: abstract_forms,
        compiler_options: compiler_options,
        module: module,
        sticky?: sticky?
      }

      {:ok, unit}
    end
  end

  def purge(module) do
    :code.purge(module)
    :code.delete(module)
  end

  def stick_module(module) do
    :code.stick_mod(module)
    ensure_loaded(module)
  end

  def unstick_module(module) do
    :ok = ensure_loaded(module)

    if :code.is_sticky(module) do
      if :code.unstick_mod(module) do
        {:ok, true}
      else
        {:error, :unable_to_unstick}
      end
    else
      {:ok, false}
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

  @spec filter_compiler_options(options :: [term()]) :: [term()]
  defp filter_compiler_options(options) do
    Enum.filter(options, fn
      {:parse_transform, _} ->
        false

      :makedeps_side_effects ->
        false

      :from_core ->
        false

      _ ->
        true
    end)
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
