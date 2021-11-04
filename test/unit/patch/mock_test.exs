defmodule Patch.Test.Unit.Patch.MockTest do
  use ExUnit.Case
  use Patch

  alias Patch.Mock
  alias Patch.Test.Support.Unit.Mock, as: MockTarget

  require Patch.Mock
  require Patch.Macro

  describe "called?/1 with no calls" do
    test "no match" do
      spy(MockTarget)

      refute Mock.called?(MockTarget.example(:test))
    end
  end

  describe "called?/1 with a single call" do
    test "exact match" do
      spy(MockTarget)

      MockTarget.example(:test)

      assert Mock.called?(MockTarget.example(:test))
    end

    test "exact mismatch" do
      spy(MockTarget)

      MockTarget.example(:test)

      refute Mock.called?(MockTarget.example(:other))
    end

    test "variable match" do
      spy(MockTarget)

      MockTarget.example(:test)

      assert Mock.called?(MockTarget.example(variable))
    end

    test "variable argument, pinned variable match" do
      spy(MockTarget)

      variable = :test

      MockTarget.example(variable)

      assert Mock.called?(MockTarget.example(^variable))
    end

    test "other variable argument, pinned variable match" do
      spy(MockTarget)

      argument = :test
      MockTarget.example(argument)

      variable = :test
      assert Mock.called?(MockTarget.example(^variable))
    end

    test "literal argument, pinned variable match" do
      spy(MockTarget)

      MockTarget.example(:test)

      variable = :test
      assert Mock.called?(MockTarget.example(^variable))
    end

    test "wildcard match" do
      spy(MockTarget)

      MockTarget.example(:test)

      assert Mock.called?(MockTarget.example(_))
    end

    test "empty list match" do
      spy(MockTarget)

      MockTarget.example([])

      assert Mock.called?(MockTarget.example([]))
    end

    test "empty list mismatch" do
      spy(MockTarget)

      MockTarget.example([:a, :b, :c])

      refute Mock.called?(MockTarget.example([]))
    end

    test "non-empty list match" do
      spy(MockTarget)

      MockTarget.example([:a, :b, :c])

      assert Mock.called?(MockTarget.example([_ | _]))
    end

    test "non-empty list mismatch" do
      spy(MockTarget)

      MockTarget.example([])

      refute Mock.called?(MockTarget.example([_ | _]))
    end

    test "empty map match" do
      spy(MockTarget)

      MockTarget.example(%{a: 1, b: 2})

      assert Mock.called?(MockTarget.example(%{}))
    end

    test "partial map match" do
      spy(MockTarget)

      MockTarget.example(%{a: 1, b: 2})

      assert Mock.called?(MockTarget.example(%{a: 1}))
      assert Mock.called?(MockTarget.example(%{b: 2}))
    end

    test "partial map mismatch" do
      spy(MockTarget)

      MockTarget.example(%{a: 1, b: 2})

      refute Mock.called?(MockTarget.example(%{c: 3}))
    end

    test "exact map match" do
      spy(MockTarget)

      MockTarget.example(%{a: 1, b: 2})

      assert Mock.called?(MockTarget.example(%{a: 1, b: 2}))
      assert Mock.called?(MockTarget.example(%{b: 2, a: 1}))
    end

    test "exact match extra key mismatch" do
      spy(MockTarget)

      MockTarget.example(%{a: 1, b: 2})

      refute Mock.called?(MockTarget.example(%{a: 1, b: 2, c: 3}))
    end

    test "arbitrary complexity match" do
      spy(MockTarget)

      MockTarget.example([1, 2, 3, %{a: 1, b: 2}])

      x = 1
      assert Mock.called?(MockTarget.example([^x, y, _, %{a: 1}]))
    end
  end

  describe "called?/1 with multiple calls" do
    test "exact match" do
      spy(MockTarget)

      MockTarget.example(:a)
      MockTarget.example(:b)
      MockTarget.example(:c)

      assert Mock.called?(MockTarget.example(:a))
      assert Mock.called?(MockTarget.example(:b))
      assert Mock.called?(MockTarget.example(:c))
    end

    test "exact mismatch" do
      spy(MockTarget)

      MockTarget.example(:a)
      MockTarget.example(:b)
      MockTarget.example(:c)

      refute Mock.called?(MockTarget.example(:d))
      refute Mock.called?(MockTarget.example(:e))
      refute Mock.called?(MockTarget.example(:f))
    end

    test "variable match" do
      spy(MockTarget)

      MockTarget.example(:a)
      MockTarget.example(:b)
      MockTarget.example(:c)

      assert Mock.called?(MockTarget.example(variable))
    end

    test "variable argument, pinned variable match" do
      spy(MockTarget)

      variable_a = :a
      variable_b = :b
      variable_c = :c

      MockTarget.example(variable_a)
      MockTarget.example(variable_b)
      MockTarget.example(variable_c)

      assert Mock.called?(MockTarget.example(^variable_a))
      assert Mock.called?(MockTarget.example(^variable_b))
      assert Mock.called?(MockTarget.example(^variable_c))
    end

    test "other variable argument, pinned variable match" do
      spy(MockTarget)

      argument_a = :a
      argument_b = :b
      argument_c = :c

      MockTarget.example(argument_a)
      MockTarget.example(argument_b)
      MockTarget.example(argument_c)

      variable_a = :a
      variable_b = :b
      variable_c = :c

      assert Mock.called?(MockTarget.example(^variable_a))
      assert Mock.called?(MockTarget.example(^variable_b))
      assert Mock.called?(MockTarget.example(^variable_c))
    end

    test "literal argument, pinned variable match" do
      spy(MockTarget)

      MockTarget.example(:a)
      MockTarget.example(:b)
      MockTarget.example(:c)

      variable_a = :a
      variable_b = :b
      variable_c = :c

      assert Mock.called?(MockTarget.example(^variable_a))
      assert Mock.called?(MockTarget.example(^variable_b))
      assert Mock.called?(MockTarget.example(^variable_c))
    end

    test "wildcard match" do
      spy(MockTarget)

      MockTarget.example(:a)
      MockTarget.example(:b)
      MockTarget.example(:c)

      assert Mock.called?(MockTarget.example(_))
    end

    test "empty list match" do
      spy(MockTarget)

      MockTarget.example([])
      MockTarget.example([:a])
      MockTarget.example([:a, :b])

      assert Mock.called?(MockTarget.example([]))
    end

    test "empty list mismatch" do
      spy(MockTarget)

      MockTarget.example([:a])
      MockTarget.example([:a, :b])
      MockTarget.example([:a, :b, :c])

      refute Mock.called?(MockTarget.example([]))
    end

    test "non-empty list match" do
      spy(MockTarget)

      MockTarget.example([:a])
      MockTarget.example([:a, :b])
      MockTarget.example([:a, :b, :c])

      assert Mock.called?(MockTarget.example([_ | _]))
    end

    test "non-empty list mismatch" do
      spy(MockTarget)

      MockTarget.example([])
      MockTarget.example([])
      MockTarget.example([])

      refute Mock.called?(MockTarget.example([_ | _]))
    end

    test "empty map match" do
      spy(MockTarget)

      MockTarget.example(%{a: 1})
      MockTarget.example(%{a: 1, b: 2})
      MockTarget.example(%{a: 1, b: 2, c: 3})

      assert Mock.called?(MockTarget.example(%{}))
    end

    test "partial map match" do
      spy(MockTarget)

      MockTarget.example(%{a: 1})
      MockTarget.example(%{a: 1, b: 2})
      MockTarget.example(%{a: 1, b: 2, c: 3})

      assert Mock.called?(MockTarget.example(%{a: 1}))
      assert Mock.called?(MockTarget.example(%{b: 2}))
      assert Mock.called?(MockTarget.example(%{c: 3}))

      assert Mock.called?(MockTarget.example(%{a: 1, b:  2}))
      assert Mock.called?(MockTarget.example(%{b: 2, a:  1}))

      assert Mock.called?(MockTarget.example(%{a: 1, c:  3}))
      assert Mock.called?(MockTarget.example(%{c: 3, a:  1}))

      assert Mock.called?(MockTarget.example(%{b: 2, c:  3}))
      assert Mock.called?(MockTarget.example(%{c: 3, b:  2}))
    end

    test "partial map mismatch" do
      spy(MockTarget)

      MockTarget.example(%{a: 1})
      MockTarget.example(%{a: 1, b: 2})
      MockTarget.example(%{a: 1, b: 2, c: 3})

      refute Mock.called?(MockTarget.example(%{d: 4}))
    end

    test "exact map match" do
      spy(MockTarget)

      MockTarget.example(%{a: 1})
      MockTarget.example(%{a: 1, b: 2})
      MockTarget.example(%{a: 1, b: 2, c: 3})

      assert Mock.called?(MockTarget.example(%{a: 1}))
      assert Mock.called?(MockTarget.example(%{a: 1, b: 2}))
      assert Mock.called?(MockTarget.example(%{a: 1, b: 2, c: 3}))
    end

    test "exact match extra key mismatch" do
      spy(MockTarget)

      MockTarget.example(%{a: 1, b: 2})

      refute Mock.called?(MockTarget.example(%{a: 1, b: 2, c: 3}))
    end

    test "arbitrary complexity match" do
      spy(MockTarget)

      MockTarget.example(:a)
      MockTarget.example(:b)
      MockTarget.example([1, 2, 3, %{a: 1, b: 2}])

      x = 1
      assert Mock.called?(MockTarget.example([^x, y, _, %{a: 1}]))
    end
  end

  describe "matches/1 with no calls" do
    test "has no matching calls" do
      spy(MockTarget)

      assert Mock.matches(MockTarget.example(:test)) == []
    end
  end

  describe "matches/1 with single call" do
    test "exact match" do
      spy(MockTarget)

      MockTarget.example(:test)

      assert Mock.matches(MockTarget.example(:test)) == [
        [:test]
      ]
    end

    test "exact mismatch" do
      spy(MockTarget)

      MockTarget.example(:test)

      assert Mock.matches(MockTarget.example(:other)) == []
    end

    test "variable match" do
      spy(MockTarget)

      MockTarget.example(:test)

      assert Mock.matches(MockTarget.example(variable)) == [
        [:test]
      ]
    end

    test "variable argument, pinned variable match" do
      spy(MockTarget)

      variable = :test

      MockTarget.example(variable)

      assert Mock.matches(MockTarget.example(^variable)) == [
        [:test]
      ]
    end

    test "other variable argument, pinned variable match" do
      spy(MockTarget)

      argument = :test
      MockTarget.example(argument)

      variable = :test
      assert Mock.matches(MockTarget.example(^variable)) == [
        [:test]
      ]
    end

    test "literal argument, pinned variable match" do
      spy(MockTarget)

      MockTarget.example(:test)

      variable = :test
      assert Mock.matches(MockTarget.example(^variable)) == [
        [:test]
      ]
    end

    test "wildcard match" do
      spy(MockTarget)

      MockTarget.example(:test)

      assert Mock.matches(MockTarget.example(_)) == [
        [:test]
      ]
    end

    test "empty list match" do
      spy(MockTarget)

      MockTarget.example([])

      assert Mock.matches(MockTarget.example([])) == [
        [[]]
      ]
    end

    test "empty list mismatch" do
      spy(MockTarget)

      MockTarget.example([:a, :b, :c])

      assert Mock.matches(MockTarget.example([])) == []
    end

    test "non-empty list match" do
      spy(MockTarget)

      MockTarget.example([:a, :b, :c])

      assert Mock.matches(MockTarget.example([_ | _])) == [
        [[:a, :b, :c]]
      ]
    end

    test "non-empty list mismatch" do
      spy(MockTarget)

      MockTarget.example([])

      assert Mock.matches(MockTarget.example([_ | _])) == []
    end

    test "empty map match" do
      spy(MockTarget)

      MockTarget.example(%{a: 1, b: 2})

      assert Mock.matches(MockTarget.example(%{})) == [
        [%{a: 1, b: 2}]
      ]
    end

    test "partial map match" do
      spy(MockTarget)

      MockTarget.example(%{a: 1, b: 2})

      assert Mock.matches(MockTarget.example(%{a: 1})) == [
        [%{a: 1, b: 2}]
      ]

      assert Mock.matches(MockTarget.example(%{b: 2})) == [
        [%{a: 1, b: 2}]
      ]
    end

    test "partial map mismatch" do
      spy(MockTarget)

      MockTarget.example(%{a: 1, b: 2})

      assert Mock.matches(MockTarget.example(%{c: 3})) == []
    end

    test "exact map match" do
      spy(MockTarget)

      MockTarget.example(%{a: 1, b: 2})

      assert Mock.matches(MockTarget.example(%{a: 1, b: 2})) == [
        [%{a: 1, b: 2}]
      ]

      assert Mock.matches(MockTarget.example(%{b: 2, a: 1})) == [
        [%{a: 1, b: 2}]
      ]
    end

    test "exact match extra key mismatch" do
      spy(MockTarget)

      MockTarget.example(%{a: 1, b: 2})

      assert Mock.matches(MockTarget.example(%{a: 1, b: 2, c: 3})) == []
    end

    test "arbitrary complexity match" do
      spy(MockTarget)

      MockTarget.example([1, 2, 3, %{a: 1, b: 2}])

      x = 1
      assert Mock.matches(MockTarget.example([^x, y, _, %{a: 1}])) == [
        [[1, 2, 3, %{a: 1, b: 2}]]
      ]
    end
  end

  describe "matches/1 with multiple calls" do
    test "exact match" do
      spy(MockTarget)

      MockTarget.example(:a)
      MockTarget.example(:b)
      MockTarget.example(:c)

      assert Mock.matches(MockTarget.example(:a)) == [
        [:a]
      ]

      assert Mock.matches(MockTarget.example(:b)) == [
        [:b]
      ]

      assert Mock.matches(MockTarget.example(:c)) == [
        [:c]
      ]
    end

    test "exact mismatch" do
      spy(MockTarget)

      MockTarget.example(:a)
      MockTarget.example(:b)
      MockTarget.example(:c)

      assert Mock.matches(MockTarget.example(:d)) == []
      assert Mock.matches(MockTarget.example(:e)) == []
      assert Mock.matches(MockTarget.example(:f)) == []
    end

    test "variable match" do
      spy(MockTarget)

      MockTarget.example(:a)
      MockTarget.example(:b)
      MockTarget.example(:c)

      assert Mock.matches(MockTarget.example(variable)) == [
        [:c],
        [:b],
        [:a]
      ]
    end

    test "variable argument, pinned variable match" do
      spy(MockTarget)

      variable_a = :a
      variable_b = :b
      variable_c = :c

      MockTarget.example(variable_a)
      MockTarget.example(variable_b)
      MockTarget.example(variable_c)

      assert Mock.matches(MockTarget.example(^variable_a)) == [
        [:a]
      ]

      assert Mock.matches(MockTarget.example(^variable_b)) == [
        [:b]
      ]

      assert Mock.matches(MockTarget.example(^variable_c)) == [
        [:c]
      ]
    end

    test "other variable argument, pinned variable match" do
      spy(MockTarget)

      argument_a = :a
      argument_b = :b
      argument_c = :c

      MockTarget.example(argument_a)
      MockTarget.example(argument_b)
      MockTarget.example(argument_c)

      variable_a = :a
      variable_b = :b
      variable_c = :c

      assert Mock.matches(MockTarget.example(^variable_a)) == [
        [:a]
      ]

      assert Mock.matches(MockTarget.example(^variable_b)) == [
        [:b]
      ]

      assert Mock.matches(MockTarget.example(^variable_c)) == [
        [:c]
      ]
    end

    test "literal argument, pinned variable match" do
      spy(MockTarget)

      MockTarget.example(:a)
      MockTarget.example(:b)
      MockTarget.example(:c)

      variable_a = :a
      variable_b = :b
      variable_c = :c

      assert Mock.matches(MockTarget.example(^variable_a)) == [
        [:a]
      ]

      assert Mock.matches(MockTarget.example(^variable_b)) == [
        [:b]
      ]

      assert Mock.matches(MockTarget.example(^variable_c)) == [
        [:c]
      ]
    end

    test "wildcard match" do
      spy(MockTarget)

      MockTarget.example(:a)
      MockTarget.example(:b)
      MockTarget.example(:c)

      assert Mock.matches(MockTarget.example(_)) == [
        [:c],
        [:b],
        [:a]
      ]
    end

    test "empty list match" do
      spy(MockTarget)

      MockTarget.example([])
      MockTarget.example([:a])
      MockTarget.example([:a, :b])

      assert Mock.matches(MockTarget.example([])) == [
        [[]]
      ]
    end

    test "empty list mismatch" do
      spy(MockTarget)

      MockTarget.example([:a])
      MockTarget.example([:a, :b])
      MockTarget.example([:a, :b, :c])

      assert Mock.matches(MockTarget.example([])) == []
    end

    test "non-empty list match" do
      spy(MockTarget)

      MockTarget.example([:a])
      MockTarget.example([:a, :b])
      MockTarget.example([:a, :b, :c])

      assert Mock.matches(MockTarget.example([_ | _])) == [
        [[:a, :b, :c]],
        [[:a, :b]],
        [[:a]]
      ]
    end

    test "non-empty list mismatch" do
      spy(MockTarget)

      MockTarget.example([])
      MockTarget.example([])
      MockTarget.example([])

      assert Mock.matches(MockTarget.example([_ | _])) == []
    end

    test "empty map match" do
      spy(MockTarget)

      MockTarget.example(%{a: 1})
      MockTarget.example(%{a: 1, b: 2})
      MockTarget.example(%{a: 1, b: 2, c: 3})

      assert Mock.matches(MockTarget.example(%{})) == [
        [%{a: 1, b: 2, c: 3}],
        [%{a: 1, b: 2}],
        [%{a: 1}]
      ]
    end

    test "partial map match" do
      spy(MockTarget)

      MockTarget.example(%{a: 1})
      MockTarget.example(%{a: 1, b: 2})
      MockTarget.example(%{a: 1, b: 2, c: 3})

      assert Mock.matches(MockTarget.example(%{a: 1})) == [
        [%{a: 1, b: 2, c: 3}],
        [%{a: 1, b: 2}],
        [%{a: 1}]
      ]

      assert Mock.matches(MockTarget.example(%{b: 2})) == [
        [%{a: 1, b: 2, c: 3}],
        [%{a: 1, b: 2}]
      ]

      assert Mock.matches(MockTarget.example(%{c: 3})) == [
        [%{a: 1, b: 2, c: 3}]
      ]

      assert Mock.matches(MockTarget.example(%{a: 1, b:  2})) == [
        [%{a: 1, b: 2, c: 3}],
        [%{a: 1, b: 2}]
      ]

      assert Mock.matches(MockTarget.example(%{b: 2, a:  1})) == [
        [%{a: 1, b: 2, c: 3}],
        [%{a: 1, b: 2}]
      ]

      assert Mock.matches(MockTarget.example(%{a: 1, c:  3})) == [
        [%{a: 1, b: 2, c: 3}]
      ]

      assert Mock.matches(MockTarget.example(%{c: 3, a:  1})) == [
        [%{a: 1, b: 2, c: 3}]
      ]

      assert Mock.matches(MockTarget.example(%{b: 2, c:  3})) == [
        [%{a: 1, b: 2, c: 3}]
      ]

      assert Mock.matches(MockTarget.example(%{c: 3, b:  2})) == [
        [%{a: 1, b: 2, c: 3}]
      ]
    end

    test "partial map mismatch" do
      spy(MockTarget)

      MockTarget.example(%{a: 1})
      MockTarget.example(%{a: 1, b: 2})
      MockTarget.example(%{a: 1, b: 2, c: 3})

      assert Mock.matches(MockTarget.example(%{d: 4})) == []
    end

    test "exact map match" do
      spy(MockTarget)

      MockTarget.example(%{a: 1})
      MockTarget.example(%{a: 1, b: 2})
      MockTarget.example(%{a: 1, b: 2, c: 3})

      assert Mock.matches(MockTarget.example(%{a: 1})) == [
        [%{a: 1, b: 2, c: 3}],
        [%{a: 1, b: 2}],
        [%{a: 1}]
      ]

      assert Mock.matches(MockTarget.example(%{a: 1, b: 2})) == [
        [%{a: 1, b: 2, c: 3}],
        [%{a: 1, b: 2}],
      ]

      assert Mock.matches(MockTarget.example(%{a: 1, b: 2, c: 3})) == [
        [%{a: 1, b: 2, c: 3}]
      ]
    end

    test "exact match extra key mismatch" do
      spy(MockTarget)

      MockTarget.example(%{a: 1, b: 2})

      assert Mock.matches(MockTarget.example(%{a: 1, b: 2, c: 3})) == []
    end

    test "arbitrary complexity match" do
      spy(MockTarget)

      MockTarget.example(:a)
      MockTarget.example(:b)
      MockTarget.example([1, 2, 3, %{a: 1, b: 2}])

      x = 1
      assert Mock.matches(MockTarget.example([^x, y, _, %{a: 1}])) == [
        [[1, 2, 3, %{a: 1, b: 2}]]
      ]
    end
  end

end
