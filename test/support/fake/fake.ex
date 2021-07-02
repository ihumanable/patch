defmodule Fake do
  def example(a) do
    {:fake, {:example, a}}
  end

  def another_example(a) do
    original = Patch.real(Original).another_example(a)
    {:fake, {:another_example, original, a}}
  end
end
