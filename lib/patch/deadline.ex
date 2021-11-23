defmodule Patch.Deadline do
  def deadline(function, milliseconds) do
    stop = now() + milliseconds
    parent = self()
    ref = make_ref()

    child =
      spawn(fn ->
        do_deadline(function, parent, ref)
      end)

    result = do_await_response(ref, stop, :timeout)
    Process.exit(child, :brutal_kill)

    case result do
      {:ok, result} ->
        result

      :timeout ->
        message = """
        \n
        Deadline exceeded after #{milliseconds}ms.
        """

        raise Patch.DeadlineException, message: message, error: :timeout

      {:raise, exception} ->
        exception_message =
          case exception do
            %ExUnit.AssertionError{} = exception ->
              exception
              |> ExUnit.AssertionError.message()
              |> String.trim_leading()

            %e{message: message} ->
              "** (#{inspect(e)}) #{message}"

            %{message: message} ->
              message

            other ->
              inspect(other)
          end
          |> String.replace("\n", "\n  ")

        message = """
        \n
        Deadline exceeded after #{milliseconds}ms.

        Last Raised Exception:

          #{exception_message}
        """

        raise Patch.DeadlineException, message: message, error: {:raise, exception}

      {:throw, thrown} ->
        message = """
        \n
        Deadline exceeded after #{milliseconds}ms.

        Last Thrown Value:

          #{inspect(thrown)}
        """

        raise Patch.DeadlineException, message: message, error: {:throw, thrown}
    end
  end

  defp do_await_response(ref, stop, error) do
    budget = stop - now()

    if budget <= 0 do
      error
    else
      receive do
        {:ok, ^ref, result} ->
          {:ok, result}

        {:error, ^ref, error} ->
          do_await_response(ref, stop, error)
      after
        budget ->
          error
      end
    end
  end

  defp do_deadline(function, parent, ref) do
    try do
      result = function.()
      send(parent, {:ok, ref, result})
      :ok
    rescue
      exception ->
        send(parent, {:error, ref, {:raise, exception}})
        do_deadline(function, parent, ref)
    catch
      :throw, thrown ->
        send(parent, {:error, ref, {:throw, thrown}})
        do_deadline(function, parent, ref)
    end
  end

  defp now do
    System.system_time(:millisecond)
  end
end
