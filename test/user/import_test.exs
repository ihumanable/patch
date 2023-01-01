defmodule Patch.Test.User.ImportTest do
  use ExUnit.Case

  def patch_imports(configuration) do
    module_name = Module.concat(__MODULE__, "Harness#{:erlang.unique_integer([:positive])}")

    code = """
    defmodule #{module_name} do
      use ExUnit.Case
      #{configuration}
    end
    """

    [{module, _}] = Code.compile_string(code)

    local_functions =
      :functions
      |> module.__info__()
      |> Enum.reject(fn {k, _} -> k == :__ex_unit__ end)

    local_macros = module.__info__(:macros)

    symbols = local_functions ++ local_macros

    symbols
    |> Keyword.keys()
    |> Enum.uniq()
    |> Enum.sort()
  end

  describe "default behavior" do
    test "all patch helpers are available in the test module" do
      assert patch_imports("use Patch") == [
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
  end

  describe "only option" do
    test "causes the imports to only include the provided symbols" do
      assert patch_imports("use Patch, only: [:assert_called, :patch]") == [
               :assert_called,
               :patch
             ]
    end

    test "raises a Patch.ConfigurationError when used in conjunction with :except" do
      assert_raise Patch.ConfigurationError, "Patch options :except and :only are mutually exclusive but both were provided", fn ->
        patch_imports("use Patch, only: [:assert_called, :patch], except: [:refute_called]")
      end
    end
  end

  describe "except option" do
    test "cases the imports to exclude the excepted symbols" do
      assert patch_imports("use Patch, except: [:assert_called, :patch]") == [
               :assert_any_call,
               :assert_called_once,
               :callable,
               :cycle,
               :debug,
               :expose,
               :fake,
               :history,
               :inject,
               :listen,
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

    test "raises a Patch.ConfigurationError when used in conjunction with :only" do
      assert_raise Patch.ConfigurationError, "Patch options :except and :only are mutually exclusive but both were provided", fn ->
        patch_imports("use Patch, except: [:assert_called, :patch], only: [:refute_called]")
      end
    end
  end

  describe "aliasing" do
    test "patch functionality can be imported under a different symbol" do
      configuration =
        """
        use Patch, alias: [
               assert_any_call: :alias_assert_any_call,
               assert_called: :alias_assert_called,
               assert_called_once: :alias_assert_called_once,
               callable: :alias_callable,
               cycle: :alias_cycle,
               debug: :alias_debug,
               expose: :alias_expose,
               fake: :alias_fake,
               history: :alias_history,
               inject: :alias_inject,
               listen: :alias_listen,
               patch: :alias_patch,
               private: :alias_private,
               raises: :alias_raises,
               real: :alias_real,
               refute_any_call: :alias_refute_any_call,
               refute_called: :alias_refute_called,
               refute_called_once: :alias_refute_called_once,
               replace: :alias_replace,
               restore: :alias_restore,
               scalar: :alias_scalar,
               sequence: :alias_sequence,
               spy: :alias_spy,
               throws: :alias_throws
        ]
        """

        assert patch_imports(configuration) == [
                 :alias_assert_any_call,
                 :alias_assert_called,
                 :alias_assert_called_once,
                 :alias_callable,
                 :alias_cycle,
                 :alias_debug,
                 :alias_expose,
                 :alias_fake,
                 :alias_history,
                 :alias_inject,
                 :alias_listen,
                 :alias_patch,
                 :alias_private,
                 :alias_raises,
                 :alias_real,
                 :alias_refute_any_call,
                 :alias_refute_called,
                 :alias_refute_called_once,
                 :alias_replace,
                 :alias_restore,
                 :alias_scalar,
                 :alias_sequence,
                 :alias_spy,
                 :alias_throws,
               ]
    end

    test "can be used with :only" do
      configuration =
        """
        use Patch,
            only: [:assert_called, :patch],
            alias: [
              assert_called: :alias_assert_called,
              patch: :alias_patch
            ]
        """

      assert patch_imports(configuration) == [:alias_assert_called, :alias_patch]
    end

    test "can be used with :only providing an alias to a subset of the symbols" do
      configuration =
        """
        use Patch,
            only: [:assert_called, :patch],
            alias: [assert_called: :alias_assert_called]
        """

      assert patch_imports(configuration) == [:alias_assert_called, :patch]
    end

    test "can be used with :except" do
      configuration =
        """
        use Patch,
            except: [:assert_called, :patch],
            alias: [
               assert_any_call: :alias_assert_any_call,
               assert_called_once: :alias_assert_called_once,
               callable: :alias_callable,
               cycle: :alias_cycle,
               debug: :alias_debug,
               expose: :alias_expose,
               fake: :alias_fake,
               history: :alias_history,
               inject: :alias_inject,
               listen: :alias_listen,
               private: :alias_private,
               raises: :alias_raises,
               real: :alias_real,
               refute_any_call: :alias_refute_any_call,
               refute_called: :alias_refute_called,
               refute_called_once: :alias_refute_called_once,
               replace: :alias_replace,
               restore: :alias_restore,
               scalar: :alias_scalar,
               sequence: :alias_sequence,
               spy: :alias_spy,
               throws: :alias_throws
            ]
        """

        assert patch_imports(configuration) == [
          :alias_assert_any_call,
          :alias_assert_called_once,
          :alias_callable,
          :alias_cycle,
          :alias_debug,
          :alias_expose,
          :alias_fake,
          :alias_history,
          :alias_inject,
          :alias_listen,
          :alias_private,
          :alias_raises,
          :alias_real,
          :alias_refute_any_call,
          :alias_refute_called,
          :alias_refute_called_once,
          :alias_replace,
          :alias_restore,
          :alias_scalar,
          :alias_sequence,
          :alias_spy,
          :alias_throws
        ]
    end

    test "can be used with :except providing an alias to a subset of the symbols" do
      configuration =
        """
        use Patch,
            except: [:assert_called, :patch],
            alias: [
               assert_any_call: :alias_assert_any_call,
               throws: :alias_throws
            ]
        """

        assert patch_imports(configuration) == [
          :alias_assert_any_call,
          :alias_throws,
          :assert_called_once,
          :callable,
          :cycle,
          :debug,
          :expose,
          :fake,
          :history,
          :inject,
          :listen,
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
          :spy
        ]
    end
  end
end
