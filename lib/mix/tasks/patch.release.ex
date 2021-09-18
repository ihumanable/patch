defmodule Mix.Tasks.Patch.Release do
  @moduledoc """
  Prepares Patch for the next release.
  """

  use Mix.Task

  @checkmark "✓"

  @github_checkmark ":white_checkmark:"
  @exdocs_checkmark @checkmark

  def run(_) do
    config = Mix.Project.config()
    version = config[:version]

    releases =
      "./pages/releases.etf"
      |> Path.expand()
      |> File.read!()
      |> :erlang.binary_to_term()

    [latest_release | previous_releases] = releases

    Mix.shell.info(["Preparing release of patch at version ", :cyan, version, :default_color])

    releases =
      if latest_release.version == version do
        if confirm?([:yellow, "WARNING ", :default_color, "Version ", :cyan, version, :default_color, " is already defined.  Overwrite?"]) do
          prepare_release(version, previous_releases)
        else
          releases
        end
      else
        prepare_release(version, releases)
      end

    render_files(version, releases)
  end

  def prepare_release(version, releases) do
    date = get_date()
    improvements = entries("Improvements")
    features = entries("Features")
    bugfixes = entries("Bugfixes")
    deprecations = entries("Deprecations")
    removals = entries("Removals")

    release = %{
      version: version,
      date: date,
      improvements: improvements,
      features: features,
      bugfixes: bugfixes,
      deprecations: deprecations,
      removals: removals
    }

    [release | releases]
  end

  def render_files(version, releases) do
    releases_binary = :erlang.term_to_binary(releases)

    readme_template = Path.expand("./pages/templates/README.eex")
    changelog_template = Path.expand("./pages/templates/CHANGELOG.eex")

    releases_path = Path.expand("./pages/releases.etf")
    exdocs_readme_path = Path.expand("./pages/README.md")
    github_readme_path = Path.expand("./README.md")
    changelog_path = Path.expand("./CHANGELOG.md")

    exdocs_readme = EEx.eval_file(readme_template, [version: version, checkmark: @exdocs_checkmark])
    github_readme = EEx.eval_file(readme_template, [version: version, checkmark: @github_checkmark])
    changelog = EEx.eval_file(changelog_template, [releases: releases])

    File.write!(exdocs_readme_path, exdocs_readme)
    File.write!(github_readme_path, github_readme)
    File.write!(changelog_path, changelog)
    File.write!(releases_path, releases_binary)

    info(["Version ", :cyan, version, :default_color, " has been ", :green, "successfully", :default_color, " prepared for release. 🚀"])
  end

  def get_date do
    today =
      Date.utc_today()
      |> Date.to_string()

    case prompt(["Date ", :cyan, today, :default_color, " (leave blank to use, or provide a custom date)"]) do
      "" ->
        today

      date ->
        date
    end
  end

  def entries(prompt, acc \\ []) do
    case prompt([:cyan, prompt, :default_color, " (leave blank when done)"]) do
      "" ->
        acc

      entry ->
        entries(prompt, [entry | acc])
    end
  end

  def info(message) do
    Mix.shell.info(message)
  end

  def prompt(prompt) do
    prompt
    |> IO.ANSI.format()
    |> IO.iodata_to_binary()
    |> Mix.shell.prompt()
    |> String.trim()
  end

  def confirm?(prompt) do
    prompt
    |> IO.ANSI.format()
    |> IO.iodata_to_binary()
    |> Mix.shell.yes?()
  end
end
