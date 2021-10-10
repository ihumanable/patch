defmodule Patch.Example do
  def example(a, b, c) do
    {a, b, c}
  end

  def caller(a) do
    callee(a)
  end

  defp callee(a) do
    {:callee, a}
  end
end
