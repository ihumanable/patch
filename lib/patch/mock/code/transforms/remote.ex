defmodule Patch.Mock.Code.Transforms.Remote do
  alias Patch.Mock.Code

  @generated [generated: true]

  @doc """
  Transforms the provided forms to rewrite any local call into a remote call to
  the provided `module`.
  """
  @spec transform(abstract_forms :: [Code.form()], module :: module()) :: [Code.form()]
  def transform(abstract_forms, module) do
    exports = Code.Query.exports(abstract_forms)

    Enum.map(abstract_forms, fn
      {:function, anno, name, arity, clauses} ->
        {:function, anno, name, arity, clauses(clauses, module, exports)}

      other ->
        other
    end)
  end

  ## Private

  @spec clauses(abstract_forms :: [Code.form()], module :: module(), exports :: Code.exports()) ::
          [Code.form()]
  defp clauses(abstract_forms, module, exports) do
    Enum.map(abstract_forms, fn
      {:clause, anno, patterns, guards, body} ->
        {:clause, anno, patterns, guards, expressions(body, module, exports)}
    end)
  end

  @spec expression(abstract_form :: Code.form(), module :: module(), exports :: Code.exports()) ::
          Code.form()
  defp expression({:call, anno, {:remote, _, _, _} = remote, arguments}, module, exports) do
    {:call, anno, remote, expressions(arguments, module, exports)}
  end

  defp expression({:call, anno, local, arguments}, module, exports) do
    arity = Enum.count(arguments)

    case local do
      {:atom, _, name} ->
        if {name, arity} in exports do
          {:call, anno, {:remote, @generated, {:atom, @generated, module}, local},
           expressions(arguments, module, exports)}
        else
          {:call, anno, local, expressions(arguments, module, exports)}
        end

      _ ->
        {:call, anno, local, expressions(arguments, module, exports)}
    end
  end

  defp expression({:block, anno, body}, module, exports) do
    {:block, anno, expressions(body, module, exports)}
  end

  defp expression({:case, anno, expression, clauses}, module, exports) do
    {:case, anno, expression(expression, module, exports), clauses(clauses, module, exports)}
  end

  defp expression({:catch, anno, expression}, module, exports) do
    {:catch, anno, expression(expression, module, exports)}
  end

  defp expression({:cons, anno, head, tail}, module, exports) do
    {:cons, anno, expression(head, module, exports), expression(tail, module, exports)}
  end

  defp expression({:fun, anno, {:function, name, arity}}, module, _) do
    {:fun, anno,
     {:function, {:atom, @generated, module}, {:atom, @generated, name},
      {:integer, @generated, arity}}}
  end

  defp expression({:fun, anno, {:clauses, clauses}}, module, exports) do
    {:fun, anno, {:clauses, clauses(clauses, module, exports)}}
  end

  defp expression({:named_fun, anno, name, clauses}, module, exports) do
    {:named_fun, anno, name, clauses(clauses, module, exports)}
  end

  defp expression({:if, anno, clauses}, module, exports) do
    {:if, anno, clauses(clauses, module, exports)}
  end

  defp expression({:lc, anno, expression, qualifiers}, module, exports) do
    {:lc, anno, expression(expression, module, exports), expressions(qualifiers, module, exports)}
  end

  defp expression({:map, anno, associations}, module, exports) do
    {:map, anno, expressions(associations, module, exports)}
  end

  defp expression({:map, anno, expression, associations}, module, exports) do
    {:map, anno, expression(expression, module, exports),
     expressions(associations, module, exports)}
  end

  defp expression({:map_field_assoc, anno, key, value}, module, exports) do
    {:map_field_assoc, anno, expression(key, module, exports), expression(value, module, exports)}
  end

  defp expression({:map_field_exact, anno, key, value}, module, exports) do
    {:map_field_exact, anno, expression(key, module, exports), expression(value, module, exports)}
  end

  defp expression({:match, anno, pattern, expression}, module, exports) do
    {:match, anno, pattern, expression(expression, module, exports)}
  end

  defp expression({:op, anno, operation, operand_expression}, module, exports) do
    {:op, anno, operation, expression(operand_expression, module, exports)}
  end

  defp expression({:op, anno, operation, lhs_expression, rhs_expression}, module, exports) do
    {:op, anno, operation, expression(lhs_expression, module, exports),
     expression(rhs_expression, module, exports)}
  end

  defp expression({:receive, anno, clauses}, module, exports) do
    {:receive, anno, clauses(clauses, module, exports)}
  end

  defp expression({:receive, anno, clauses, timeout_expression, body}, module, exports) do
    {:receive, anno, clauses(clauses, module, exports),
     expression(timeout_expression, module, exports), expressions(body, module, exports)}
  end

  defp expression({:record, anno, name, fields}, module, exports) do
    {:record, anno, name, expressions(fields, module, exports)}
  end

  defp expression({:record, anno, expression, name, fields}, module, exports) do
    {:record, anno, expression(expression, module, exports), name,
     expressions(fields, module, exports)}
  end

  defp expression({:record_field, anno, field, expression}, module, exports) do
    {:record_field, anno, field, expression(expression, module, exports)}
  end

  defp expression({:record_field, anno, expression, name, field}, module, exports) do
    {:record_field, anno, expression(expression, module, exports), name, field}
  end

  defp expression({:tuple, anno, expressions}, module, exports) do
    {:tuple, anno, expressions(expressions, module, exports)}
  end

  defp expression({:try, anno, body, case_clauses, catch_clauses}, module, exports) do
    {
      :try,
      anno,
      expressions(body, module, exports),
      clauses(case_clauses, module, exports),
      clauses(catch_clauses, module, exports)
    }
  end

  defp expression({:try, anno, body, case_clauses, catch_clauses, after_body}, module, exports) do
    {
      :try,
      anno,
      expressions(body, module, exports),
      clauses(case_clauses, module, exports),
      clauses(catch_clauses, module, exports),
      expressions(after_body, module, exports)
    }
  end

  defp expression(other, _, _) do
    other
  end

  @spec expressions(
          abstract_forms :: [Code.form()],
          module :: module(),
          exports :: Code.exports()
        ) :: [Code.form()]
  defp expressions(abstract_forms, module, exports) do
    Enum.map(abstract_forms, &expression(&1, module, exports))
  end
end
