defmodule Mix.Tasks.Patch.Release do
  @moduledoc """
  Prepares Patch for the next release.

  It is expected that the version will be updated in mix.exs **before** running
  this tool.

  This tool will collect some necessary information for the changelog.

  There are some minor differences in how Github and ExDocs want to link and
  render things.  This task also takes care of generating custom markdown that
  renders properly in Github and ExDocs.  Github markdown files end up in the
  root of the project, the ExDocs markdown files end up in /pages and are
  included via extras in mix.exs.
  """
  @shortdoc "Prepares Patch for the next release."

  use Mix.Task

  @exdocs_links %{
    assert_refute_calls: "#asserting-refuting-calls",
    changelog: "changelog.html"
  }

  @github_links %{
    assert_refute_calls: "#asserting--refuting-calls",
    changelog: "CHANGELOG.md"
  }

  def run(_) do
    config = Mix.Project.config()
    version = config[:version]

    releases =
      "./pages/templates/releases.etf"
      |> Path.expand()
      |> File.read!()
      |> :erlang.binary_to_term()

    [latest_release | previous_releases] = releases

    Mix.shell().info(["Preparing release of patch at version ", :cyan, version, :default_color])

    releases =
      if latest_release.version == version do
        if confirm?([
             :yellow,
             "WARNING ",
             :default_color,
             "Version ",
             :cyan,
             version,
             :default_color,
             " is already defined.  Overwrite?"
           ]) do
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
    releases_path = Path.expand("./pages/templates/releases.etf")

    exdocs_changelog_path = Path.expand("./pages/CHANGELOG.md")
    github_changelog_path = Path.expand("./CHANGELOG.md")

    exdocs_readme_path = Path.expand("./pages/README.md")
    github_readme_path = Path.expand("./README.md")

    exdocs_changelog = EEx.eval_file(changelog_template, releases: releases)
    github_changelog = EEx.eval_file(changelog_template, releases: releases)

    exdocs_readme = EEx.eval_file(readme_template, version: version, links: @exdocs_links)
    github_readme = EEx.eval_file(readme_template, version: version, links: @github_links)

    File.write!(exdocs_changelog_path, exdocs_changelog)
    File.write!(github_changelog_path, github_changelog)

    File.write!(exdocs_readme_path, exdocs_readme)
    File.write!(github_readme_path, github_readme)

    File.write!(releases_path, releases_binary)

    info([
      "Version ",
      :cyan,
      version,
      :default_color,
      " has been ",
      :green,
      "successfully",
      :default_color,
      " prepared for release. 🚀"
    ])
  end

  def get_date do
    today =
      Date.utc_today()
      |> Date.to_string()

    case prompt([
           "Date ",
           :cyan,
           today,
           :default_color,
           " (leave blank to use, or provide a custom date)"
         ]) do
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
    Mix.shell().info(message)
  end

  def prompt(prompt) do
    prompt
    |> IO.ANSI.format()
    |> IO.iodata_to_binary()
    |> Mix.shell().prompt()
    |> String.trim()
  end

  def confirm?(prompt) do
    prompt
    |> IO.ANSI.format()
    |> IO.iodata_to_binary()
    |> Mix.shell().yes?()
  end
end
