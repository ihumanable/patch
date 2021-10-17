defmodule Patch.Test.Support.User.Fake.Fake do
  alias Patch.Test.Support.User.Fake.Real

  def example(a) do
    {:fake, {:example, a}}
  end

  def delegate(a) do
    real = Patch.real(Real).delegate(a)
    {:fake, real}
  end
end
