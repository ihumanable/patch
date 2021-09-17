defmodule Patch.Test.Support.Fake.Real do
  def example(a) do
    {:real, {:example, a}}
  end

  def delegate(a) do
    {:real, {:delegate, a}}
  end
end
