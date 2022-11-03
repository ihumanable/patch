defmodule Patch.Importer do
  defmacro __using__(options \\ []) do
    validate_keyword_options!(options)
    validate_unknown_options!(options)
    validate_mutually_exclusive_options!(options)
    validate_alias_option!(options[:alias])
    validate_except_option!(options[:except])
    validate_only_option!(options[:only])

    delegates =
      all()
      |> exclude(options[:except])
      |> include(options[:only])
      |> aliasing(options[:alias])
      |> Enum.map(&delegate/1)

    quote do
      require Patch
      require Patch.Assertions
      require Patch.Macro
      require Patch.Mock
      require Patch.Mock.History.Tagged

      unquote_splicing(delegates)
    end
  end

  def all() do
    [
      :assert_any_call,
      :assert_called,
      :assert_called_once,
      :callable,
      :cycle,
      :debug,
      :expose,
      :fake,
      :history,
      :inject,
      :listen,
      :patch,
      :private,
      :raises,
      :real,
      :refute_any_call,
      :refute_called,
      :refute_called_once,
      :replace,
      :restore,
      :scalar,
      :sequence,
      :spy,
      :throws
    ]
  end

  ## Delegation

  defp delegate({:assert_any_call, symbol}) do
    quote do
      defmacro unquote(symbol)(call) do
        quote do
          Patch.assert_any_call(unquote(call))
        end
      end

      defdelegate unquote(symbol)(module, function), to: Patch, as: :assert_any_call
    end
  end

  defp delegate({:assert_called, symbol}) do
    quote do
      defmacro unquote(symbol)(call) do
        quote do
          Patch.assert_called(unquote(call))
        end
      end

      defmacro unquote(symbol)(call, count) do
        quote do
          Patch.assert_called(unquote(call), unquote(count))
        end
      end
    end
  end

  defp delegate({:assert_called_once, symbol}) do
    quote do
      defmacro unquote(symbol)(call) do
        quote do
          Patch.assert_called_once(unquote(call))
        end
      end
    end
  end

  defp delegate({:callable, symbol}) do
    quote do
      defdelegate unquote(symbol)(target), to: Patch.Mock.Value, as: :callable
      defdelegate unquote(symbol)(target, dispatch_or_options), to: Patch.Mock.Value, as: :callable
    end
  end

  defp delegate({:cycle, symbol}) do
    quote do
      defdelegate unquote(symbol)(values), to: Patch.Mock.Value, as: :cycle
    end
  end

  defp delegate({:debug, symbol}) do
    quote do
      defdelegate unquote(symbol)(), to: Patch, as: :debug
      defdelegate unquote(symbol)(value), to: Patch, as: :debug
    end
  end

  defp delegate({:expose, symbol}) do
    quote do
      defdelegate unquote(symbol)(module, exposes), to: Patch, as: :expose
    end
  end

  defp delegate({:fake, symbol}) do
    quote do
      defdelegate unquote(symbol)(real_module, fake_module), to: Patch, as: :fake
    end
  end

  defp delegate({:inject, symbol}) do
    quote do
      defdelegate unquote(symbol)(tag, target, keys), to: Patch, as: :inject
      defdelegate unquote(symbol)(tag, target, keys, options), to: Patch, as: :inject
    end
  end

  defp delegate({:is_value, symbol}) do
    quote do
      defguard unquote(symbol)(module) when Patch.Mock.Value.is_value(module)
    end
  end

  defp delegate({:history, symbol}) do
    quote do
      defdelegate unquote(symbol)(module), to: Patch, as: :history
      defdelegate unquote(symbol)(module, sorting), to: Patch, as: :history
    end
  end

  defp delegate({:listen, symbol}) do
    quote do
      defdelegate unquote(symbol)(tag, target), to: Patch, as: :listen
      defdelegate unquote(symbol)(tag, target, options), to: Patch, as: :listen
    end
  end

  defp delegate({:patch, symbol}) do
    quote do
      defdelegate unquote(symbol)(module, function, value), to: Patch, as: :patch
    end
  end

  defp delegate({:private, symbol}) do
    quote do
      defmacro unquote(symbol)(call) do
        quote do
          Patch.private(unquote(call))
        end
      end

      defmacro unquote(symbol)(argument, call) do
        quote do
          Patch.private(unquote(argument), unquote(call))
        end
      end
    end
  end

  defp delegate({:raises, symbol}) do
    quote do
      defdelegate unquote(symbol)(message), to: Patch.Mock.Value, as: :raises
      defdelegate unquote(symbol)(exception, attributes), to: Patch.Mock.Value, as: :raises
    end
  end

  defp delegate({:real, symbol}) do
    quote do
      defdelegate unquote(symbol)(module), to: Patch, as: :real
    end
  end

  defp delegate({:refute_any_call, symbol}) do
    quote do
      defmacro unquote(symbol)(call) do
        quote do
          Patch.refute_any_call(unquote(call))
        end
      end

      defdelegate unquote(symbol)(module, function), to: Patch, as: :refute_any_call
    end
  end

  defp delegate({:refute_called, symbol}) do
    quote do
      defmacro unquote(symbol)(call) do
        quote do
          Patch.refute_called(unquote(call))
        end
      end

      defmacro unquote(symbol)(call, count) do
        quote do
          Patch.refute_called(unquote(call), unquote(count))
        end
      end
    end
  end

  defp delegate({:refute_called_once, symbol}) do
    quote do
      defmacro unquote(symbol)(call) do
        quote do
          Patch.refute_called_once(unquote(call))
        end
      end
    end
  end

  defp delegate({:replace, symbol}) do
    quote do
      defdelegate unquote(symbol)(target, keys, value), to: Patch, as: :replace
    end
  end

  defp delegate({:restore, symbol}) do
    quote do
      defdelegate unquote(symbol)(module), to: Patch, as: :restore
      defdelegate unquote(symbol)(module, name), to: Patch, as: :restore
    end
  end

  defp delegate({:scalar, symbol}) do
    quote do
      defdelegate unquote(symbol)(value), to: Patch.Mock.Value, as: :scalar
    end
  end

  defp delegate({:sequence, symbol}) do
    quote do
      defdelegate unquote(symbol)(values), to: Patch.Mock.Value, as: :sequence
    end
  end

  defp delegate({:spy, symbol}) do
    quote do
      defdelegate unquote(symbol)(module), to: Patch, as: :spy
    end
  end

  defp delegate({:throws, symbol}) do
    quote do
      defdelegate unquote(symbol)(value), to: Patch.Mock.Value, as: :throws
    end
  end


  ## Private

  defp aliasing(symbols, nil) do
    Keyword.new(symbols, &{&1, &1})
  end

  defp aliasing(symbols, aliases) do
    Keyword.new(symbols, fn symbol ->
      {symbol, aliases[symbol] || symbol}
    end)
  end

  defp exclude(symbols, nil) do
    symbols
  end

  defp exclude(_symbols, :all) do
    []
  end

  defp exclude(symbols, except) do
    Enum.reject(symbols, & &1 in except)
  end

  defp include(symbols, nil) do
    symbols
  end

  defp include(symbols, only) do
    Enum.filter(symbols, & &1 in only)
  end

  defp validate_keyword_options!(options) do
    unless Keyword.keyword?(options) do
      raise Patch.ConfigurationError, message: "Patch only accepts a Keyword for configuration, invalid configuration provided"
    end
  end

  defp validate_unknown_options!(options) do
    keys = Keyword.keys(options)

    invalid_keys = keys -- [:alias, :except, :only]

    unless Enum.empty?(invalid_keys) do
      raise Patch.ConfigurationError, message: "Patch only accepts the :alias, :except, and :only configuration keys, invalid configuration keys provided: #{inspect(invalid_keys)}"
    end
  end

  defp validate_mutually_exclusive_options!(options) do
    if Keyword.has_key?(options, :except) and Keyword.has_key?(options, :only) do
      raise Patch.ConfigurationError, message: "Patch options :except and :only are mutually exclusive but both were provided"
    end
  end

  defp validate_alias_option!(nil) do
    :ok
  end

  defp validate_alias_option!(aliases) do
    unless Keyword.keyword?(aliases) do
      raise Patch.ConfigurationError, message: "Patch option :alias accepts a Keyword mapping patch symbols to aliases, the provided value is invalid because it is not a Keyword"
    end

    known_symbols = all()
    unknown_symbols =
      aliases
      |> Keyword.keys()
      |> Enum.reject(& &1 in known_symbols)

    unless Enum.empty?(unknown_symbols) do
      raise Patch.ConfigurationError, message: "Patch option :alias accepts a Keyword mapping patch symbols to aliases, the provided valus is invalid because it contains unknown symbols: #{inspect(unknown_symbols)}"
    end

    all_atoms? =
      aliases
      |> Keyword.values()
      |> Enum.all?(&is_atom/1)

    unless all_atoms? do
      raise Patch.ConfigurationError, message: "Patch option :alias accepts a Keyword mapping patch symbols to aliases, the provided value is invalid becasue it contains aliases that are not atoms"
    end

    :ok
  end

  defp validate_except_option!(nil) do
    :ok
  end

  defp validate_except_option!(:all) do
    :ok
  end

  defp validate_except_option!(except) when not is_list(except) do
    raise Patch.ConfigurationError, message: "Patch option :except accepts either the atom `:all` or a list of atoms to exclude from importing, the provided value is invalid because it is neither of these"
  end

  defp validate_except_option!(except) do
    unless Enum.all?(except, &is_atom/1) do
      raise Patch.ConfigurationError, message: "Patch option :except accepts a list of atoms to exclude from importing, the provided value is invalid because it contains values that are not atoms"
    end

    known_symbols = all()
    unknown_symbols = Enum.reject(except, & &1 in known_symbols)

    unless Enum.empty?(unknown_symbols) do
      raise Patch.ConfigurationError, message: "Patch option :excpet accepts a list of atoms to exclude from importing, the provided value is invalid because it contains unknown symbols: #{inspect(unknown_symbols)}"
    end

    :ok
  end

  defp validate_only_option!(nil) do
    :ok
  end

  defp validate_only_option!(only) when not is_list(only) do
    raise Patch.ConfigurationError, message: "Patch option :only accepts a list of atoms to import, the provided value is invalid because it is not a list"
  end

  defp validate_only_option!(only) do
    unless Enum.all?(only, &is_atom/1) do
      raise Patch.ConfigurationError, message: "Patch option :only accepts a list of atoms to import, the provided value is invalid because it contains values that are not atoms"
    end

    known_symbols = all()
    unknown_symbols = Enum.reject(only, & &1 in known_symbols)

    unless Enum.empty?(unknown_symbols) do
      raise Patch.ConfigurationError, message: "Patch option :only accepts a list of atoms to import, the provided value is invalid because it contains unknown symbols: #{inspect(unknown_symbols)}"
    end

    :ok
  end
end
