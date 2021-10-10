defmodule Patch.Mock.Code.Transforms.Remote do
  alias Patch.Mock.Code

  @generated [generated: true]

  @doc """
  Transforms the provided forms to rewrite any local call into a remote call to
  the provided `module`.
  """
  @spec transform(abstract_forms :: [Code.form()], module :: module()) :: [Code.form()]
  def transform(abstract_forms, module) do
    Enum.map(abstract_forms, fn
      {:function, anno, name, arity, clauses} ->
        {:function, anno, name, arity, clauses(clauses, module)}

      other ->
        other
    end)
  end

  ## Private

  @spec clauses(abstract_forms :: [Code.form()], module :: module()) :: [Code.form()]
  defp clauses(abstract_forms, module) do
    Enum.map(abstract_forms, fn
      {:clause, anno, patterns, guards, body} ->
        {:clause, anno, patterns, guards, expressions(body, module)}
    end)
  end

  @spec expression(abstract_form :: Code.form(), module :: module()) :: Code.form()
  defp expression({:call, _, {:remote, _, _, _}, _} = remote_call, _) do
    remote_call
  end

  defp expression({:call, anno, local, arguments}, module) do
    {:call, anno,
      {:remote, @generated, {:atom, @generated, module}, local},
      expressions(arguments, module)
    }
  end

  defp expression({:block, anno, body}, module) do
    {:block, anno, expressions(body, module)}
  end

  defp expression({:case, anno, expression, clauses}, module) do
    {:case, anno, expression(expression, module), clauses(clauses, module)}
  end

  defp expression({:catch, anno, expression}, module) do
    {:catch, anno, expression(expression, module)}
  end

  defp expression({:cons, anno, head, tail}, module) do
    {:cons, anno, expression(head, module), expression(tail, module)}
  end

  defp expression({:fun, anno, {:function, name, arity}}, module) do
    {:fun, anno,
     {:function, {:atom, @generated, module}, {:atom, @generated, name},
      {:integer, @generated, arity}}}
  end

  defp expression({:fun, anno, {:clauses, clauses}}, module) do
    {:fun, anno, {:clauses, clauses(clauses, module)}}
  end

  defp expression({:named_fun, anno, name, clauses}, module) do
    {:named_fun, anno, name, clauses(clauses, module)}
  end

  defp expression({:if, anno, clauses}, module) do
    {:if, anno, clauses(clauses, module)}
  end

  defp expression({:lc, anno, expression, qualifiers}, module) do
    {:lc, anno, expression(expression, module), expressions(qualifiers, module)}
  end

  defp expression({:map, anno, associations}, module) do
    {:map, anno, expressions(associations, module)}
  end

  defp expression({:map, anno, expression, associations}, module) do
    {:map, anno, expression(expression, module), expressions(associations, module)}
  end

  defp expression({:map_field_assoc, anno, key, value}, module) do
    {:map_field_assoc, anno, expression(key, module), expression(value, module)}
  end

  defp expression({:map_field_exact, anno, key, value}, module) do
    {:map_field_exact, anno, expression(key, module), expression(value, module)}
  end

  defp expression({:match, anno, pattern, expression}, module) do
    {:match, anno, pattern, expression(expression, module)}
  end

  defp expression({:op, anno, operation, operand_expression}, module) do
    {:op, anno, operation, expression(operand_expression, module)}
  end

  defp expression({:op, anno, operation, lhs_expression, rhs_expression}, module) do
    {:op, anno, operation, expression(lhs_expression, module), expression(rhs_expression, module)}
  end

  defp expression({:receive, anno, clauses}, module) do
    {:receive, anno, clauses(clauses, module)}
  end

  defp expression({:receive, anno, clauses, timeout_expression, body}, module) do
    {:receive, anno, clauses(clauses, module), expression(timeout_expression, module),
     expressions(body, module)}
  end

  defp expression({:record, anno, name, fields}, module) do
    {:record, anno, name, expressions(fields, module)}
  end

  defp expression({:record, anno, expression, name, fields}, module) do
    {:record, anno, expression(expression, module), name, expressions(fields, module)}
  end

  defp expression({:record_field, anno, field, expression}, module) do
    {:record_field, anno, field, expression(expression, module)}
  end

  defp expression({:record_field, anno, expression, name, field}, module) do
    {:record_field, anno, expression(expression, module), name, field}
  end

  defp expression({:tuple, anno, expressions}, module) do
    {:tuple, anno, expressions(expressions, module)}
  end

  defp expression({:try, anno, body, case_clauses, catch_clauses}, module) do
    {
      :try,
      anno,
      expressions(body, module),
      clauses(case_clauses, module),
      clauses(catch_clauses, module)
    }
  end

  defp expression({:try, anno, body, case_clauses, catch_clauses, after_body}, module) do
    {
      :try,
      anno,
      expressions(body, module),
      clauses(case_clauses, module),
      clauses(catch_clauses, module),
      expressions(after_body, module)
    }
  end

  defp expression(other, _) do
    other
  end

  @spec expressions(abstract_forms :: [Code.form()], module :: module()) :: [Code.form()]
  defp expressions(abstract_forms, module) do
    Enum.map(abstract_forms, &expression(&1, module))
  end
end
