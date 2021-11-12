defmodule Patch.Mock.Code.Transforms.Reroute do
  alias Patch.Mock.Code

  @generated [generated: true]

  @doc """
  Transforms the provided forms to rewrite any remote calls to the `source` module into remote
  calls to the `destination` module.
  """
  @spec transform(abstract_forms :: [Code.form()], source :: module(), destination :: module()) :: [Code.form()]
  def transform(abstract_forms, source, destination) do
    Enum.map(abstract_forms, fn
      {:function, anno, name, arity, clauses} ->
        {:function, anno, name, arity, clauses(clauses, source, destination)}

      other ->
        other
    end)
  end

  ## Private

  @spec clauses(abstract_forms :: [Code.form()], source :: module(), destination :: module()) ::
          [Code.form()]
  defp clauses(abstract_forms, source, destination) do
    Enum.map(abstract_forms, fn
      {:clause, anno, patterns, guards, body} ->
        {:clause, anno, patterns, guards, expressions(body, source, destination)}
    end)
  end

  @spec expression(abstract_form :: Code.form(), source :: module(), destination :: module()) ::
          Code.form()
  defp expression({:call, _, {:remote, _, {:atom, _, source}, name}, arguments}, source, destination) do
    {
      :call,
      @generated,
      {
        :remote,
        @generated,
        {:atom, @generated, destination},
        expression(name, source, destination)
      },
      expressions(arguments, source, destination)
    }
  end

  defp expression({:call, call_anno, {:remote, remote_anno, module, name}, arguments}, source, destination) do
    {
      :call,
      call_anno,
      {
        :remote,
        remote_anno,
        expression(module, source, destination),
        expression(name, source, destination),
      },
      expressions(arguments, source, destination)
    }
  end

  defp expression({:call, anno, local, arguments}, source, destination) do
    {
      :call,
      anno,
      expression(local, source, destination),
      expressions(arguments, source, destination)
    }
  end

  defp expression({:block, anno, body}, source, destination) do
    {:block, anno, expressions(body, source, destination)}
  end

  defp expression({:case, anno, expression, clauses}, source, destination) do
    {:case, anno, expression(expression, source, destination), clauses(clauses, source, destination)}
  end

  defp expression({:catch, anno, expression}, source, destination) do
    {:catch, anno, expression(expression, source, destination)}
  end

  defp expression({:cons, anno, head, tail}, source, destination) do
    {:cons, anno, expression(head, source, destination), expression(tail, source, destination)}
  end

  defp expression({:fun, _, {:function, {:atom, _, source}, name, arity}}, source, destination) do
    {
      :fun,
      @generated,
      {
        :function,
        {:atom, @generated, destination},
        expression(name, source, destination),
        expression(arity, source, destination)
      }
    }
  end

  defp expression({:fun, anno, {:function, module, name, arity}}, source, destination) do
    {
      :fun,
      anno,
      {
        :function,
        expression(module, source, destination),
        expression(name, source, destination),
        expression(arity, source, destination)
      }
    }
  end

  defp expression({:fun, anno, {:clauses, clauses}}, source, destination) do
    {:fun, anno, {:clauses, clauses(clauses, source, destination)}}
  end

  defp expression({:named_fun, anno, name, clauses}, source, destination) do
    {:named_fun, anno, name, clauses(clauses, source, destination)}
  end

  defp expression({:if, anno, clauses}, source, destination) do
    {:if, anno, clauses(clauses, source, destination)}
  end

  defp expression({:lc, anno, expression, qualifiers}, source, destination) do
    {
      :lc,
      anno,
      expression(expression, source, destination),
      expressions(qualifiers, source, destination)
    }
  end

  defp expression({:map, anno, associations}, source, destination) do
    {:map, anno, expressions(associations, source, destination)}
  end

  defp expression({:map, anno, expression, associations}, source, destination) do
    {
      :map,
      anno,
      expression(expression, source, destination),
      expressions(associations, source, destination)
    }
  end

  defp expression({:map_field_assoc, anno, key, value}, source, destination) do
    {
      :map_field_assoc,
      anno,
      expression(key, source, destination),
      expression(value, source, destination)
    }
  end

  defp expression({:map_field_exact, anno, key, value}, source, destination) do
    {
      :map_field_exact,
      anno,
      expression(key, source, destination),
      expression(value, source, destination)
    }
  end

  defp expression({:match, anno, pattern, expression}, source, destination) do
    {:match, anno, pattern, expression(expression, source, destination)}
  end

  defp expression({:op, anno, operation, operand_expression}, source, destination) do
    {:op, anno, operation, expression(operand_expression, source, destination)}
  end

  defp expression({:op, anno, operation, lhs_expression, rhs_expression}, source, destination) do
    {
      :op,
      anno,
      operation,
      expression(lhs_expression, source, destination),
      expression(rhs_expression, source, destination)
    }
  end

  defp expression({:receive, anno, clauses}, source, destination) do
    {:receive, anno, clauses(clauses, source, destination)}
  end

  defp expression({:receive, anno, clauses, timeout_expression, body}, source, destination) do
    {
      :receive,
      anno,
      clauses(clauses, source, destination),
      expression(timeout_expression, source, destination),
      expressions(body, source, destination)
    }
  end

  defp expression({:record, anno, name, fields}, source, destination) do
    {:record, anno, name, expressions(fields, source, destination)}
  end

  defp expression({:record, anno, expression, name, fields}, source, destination) do
    {
      :record,
      anno,
      expression(expression, source, destination),
      name,
      expressions(fields, source, destination)
    }
  end

  defp expression({:record_field, anno, field, expression}, source, destination) do
    {:record_field, anno, field, expression(expression, source, destination)}
  end

  defp expression({:record_field, anno, expression, name, field}, source, destination) do
    {:record_field, anno, expression(expression, source, destination), name, field}
  end

  defp expression({:tuple, anno, expressions}, source, destination) do
    {:tuple, anno, expressions(expressions, source, destination)}
  end

  defp expression({:try, anno, body, case_clauses, catch_clauses}, source, destination) do
    {
      :try,
      anno,
      expressions(body, source, destination),
      clauses(case_clauses, source, destination),
      clauses(catch_clauses, source, destination)
    }
  end

  defp expression({:try, anno, body, case_clauses, catch_clauses, after_body}, source, destination) do
    {
      :try,
      anno,
      expressions(body, source, destination),
      clauses(case_clauses, source, destination),
      clauses(catch_clauses, source, destination),
      expressions(after_body, source, destination)
    }
  end

  defp expression(other, _, _) do
    other
  end

  @spec expressions(
          abstract_forms :: [Code.form()],
          source :: module(),
          destination :: module()
        ) :: [Code.form()]
  defp expressions(abstract_forms, source, destination) do
    Enum.map(abstract_forms, &expression(&1, source, destination))
  end
end
