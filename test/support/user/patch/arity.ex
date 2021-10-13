defmodule Patch.Test.Support.User.Patch.Arity do
  def function_of_arity_0 do
    :original
  end

  def function_of_arity_20(
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
        t
      ) do
    {:original, {a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t}}
  end
end
