defmodule Patch.Test.Support.Unit.Cover.Target do
  def double(value) do
    value * 2
  end

  def unquote(Patch.Test.Support.Unit.Cover.Source)(value) do
    value + 1
  end
end
