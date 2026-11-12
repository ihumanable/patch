# From Elixir 1.15 on, Mix keeps only the applications of the project and its
# dependencies in the code path. The cover tests need :cover from :tools.
if function_exported?(Mix, :ensure_application!, 1) do
  Mix.ensure_application!(:tools)
end

ExUnit.start()
