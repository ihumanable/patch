# From Elixir 1.15 on, Mix keeps only the applications of the project and its
# dependencies in the code path. The cover tests need :cover from :tools.
if function_exported?(Mix, :ensure_application!, 1) do
  Mix.ensure_application!(:tools)
end

# Under mix test --cover, the cover server that holds the counts of the whole
# run is running when this file is loaded. A test that kills it runs only
# against a cover server of its own.
excluded_tags =
  if Process.whereis(:cover_server),
    do: [:kills_cover_server],
    else: []

ExUnit.start(exclude: excluded_tags)
