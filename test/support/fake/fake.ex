defmodule Patch.Test.Support.Fake.Fake do
  alias Patch.Test.Support.Fake.Real

  def example(a) do
    {:fake, {:example, a}}
  end

  def delegate(a) do
    real = Patch.real(Real).delegate(a)
    {:fake, real}
  end
end
