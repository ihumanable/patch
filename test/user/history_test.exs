defmodule Patch.Test.User.HistoryTest do
  use ExUnit.Case
  use Patch

  alias Patch.Test.Support.User.History

  describe "history/2" do
    test "records the call to a function" do
      spy(History)

      assert History.public_function(:test_argument) == {:public, :test_argument}

      assert history(History) == [{:public_function, [:test_argument]}]
    end

    test "records public collaborator calls" do
      spy(History)

      assert History.public_caller(:test_argument) == {:original, {:public, :test_argument}}

      assert history(History) == [
        {:public_caller, [:test_argument]},
        {:public_function, [:test_argument]}
      ]
    end

    test "records private collaborator calls" do
      spy(History)

      assert History.private_caller(:test_argument) == {:original, {:private, :test_argument}}

      assert history(History) == [
        {:private_caller, [:test_argument]},
        {:private_function, [:test_argument]}
      ]
    end

    test "records calls to exposed private functions" do
      expose(History, :all)

      assert private(History.private_function(:test_argument)) == {:private, :test_argument}

      assert history(History) == [
        {:private_function, [:test_argument]}
      ]
    end

    test "does not record calls before patching" do
      assert History.public_function(:before_patch) == {:public, :before_patch}

      assert history(History) == []

      patch(History, :public_function, :patched)

      assert History.public_function(:after_patch) == :patched

      assert history(History) == [{:public_function, [:after_patch]}]
    end

    test "changing expose does not discard history" do
      patch(History, :public_function, :patched)

      assert History.public_function(:test_argument) == :patched

      assert history(History) == [{:public_function, [:test_argument]}]

      expose(History, :all)

      assert private(History.private_function(:test_argument)) == {:private, :test_argument}

      assert history(History) == [
        {:public_function, [:test_argument]},
        {:private_function, [:test_argument]}
      ]
    end

    test "history can be returned oldest-first (ascending) or newest-first (descending)" do
      spy(History)

      History.public_function(1)
      History.public_function(2)
      History.public_function(3)

      assert history(History) == [
        {:public_function, [1]},
        {:public_function, [2]},
        {:public_function, [3]}
      ]

      assert history(History, :asc) == [
        {:public_function, [1]},
        {:public_function, [2]},
        {:public_function, [3]}
      ]

      assert history(History, :desc) == [
        {:public_function, [3]},
        {:public_function, [2]},
        {:public_function, [1]}
      ]
    end
  end
end
