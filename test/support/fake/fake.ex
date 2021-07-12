defmodule Fake do
  def example(a) do
    {:fake, {:example, a}}
  end

  def delegate(a) do
    real = Patch.real(Real).delegate(a)
    {:fake, real}
  end
end
