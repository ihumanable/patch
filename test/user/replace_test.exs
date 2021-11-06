defmodule Patch.Test.User.ReplaceTest do
  use ExUnit.Case
  use Patch

  alias Patch.Test.Support.User.Replace
  alias Patch.Test.Support.User.Replace.Inner


  describe "replace/3 with an anonymous process" do
    test "top-level fields can be updated" do
      {:ok, pid} = Replace.start_link(:initial_value)

      replace(pid, [:value], :replaced_value)

      assert :sys.get_state(pid) == %Replace{
        value: :replaced_value,
        inner: %Inner{
          value: :initial_value
        }
      }
    end

    test "nested fields can be updated" do
      {:ok, pid} = Replace.start_link(:initial_value)

      replace(pid, [:inner, :value], :replaced_value)

      assert :sys.get_state(pid) == %Replace{
        value: :initial_value,
        inner: %Inner{
          value: :replaced_value
        }
      }
    end

    test "replaces key's value wholesale" do
      {:ok, pid} = Replace.start_link(:initial_value)

      replace(pid, [:inner], :replaced_value)

      assert :sys.get_state(pid) == %Replace{
        value: :initial_value,
        inner: :replaced_value
      }
    end
  end


  describe "replace/3 with a named process" do
    test "top-level fields can be updated" do
      {:ok, pid} = Replace.start_link(:initial_value, name: Replace)

      replace(Replace, [:value], :replaced_value)

      assert :sys.get_state(pid) == %Replace{
        value: :replaced_value,
        inner: %Inner{
          value: :initial_value
        }
      }
    end

    test "nested fields can be updated" do
      {:ok, pid} = Replace.start_link(:initial_value, name: Replace)

      replace(Replace, [:inner, :value], :replaced_value)

      assert :sys.get_state(pid) == %Replace{
        value: :initial_value,
        inner: %Inner{
          value: :replaced_value
        }
      }
    end

    test "replaces key's value wholesale" do
      {:ok, pid} = Replace.start_link(:initial_value, name: Replace)

      replace(Replace, [:inner], :replaced_value)

      assert :sys.get_state(pid) == %Replace{
        value: :initial_value,
        inner: :replaced_value
      }
    end
  end
end
