defmodule Patch.Test.Support.Example do
  def double(value) do
    value * 2
  end

  def function_with_26_arguments(
        a,
        b,
        c,
        d,
        e,
        f,
        g,
        h,
        i,
        j,
        k,
        l,
        m,
        n,
        o,
        p,
        q,
        r,
        s,
        t,
        u,
        v,
        w,
        x,
        y,
        z
      ) do
    {:alphabet, a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z}
  end

  def function_with_multiple_arities(a) do
    {a, 1}
  end

  def function_with_multiple_arities(a, b) do
    {{a, b}, 2}
  end

  def function_with_multiple_arities(a, b, c) do
    {{a, b, c}, 3}
  end
end
