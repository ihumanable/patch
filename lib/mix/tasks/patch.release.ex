defmodule Mix.Tasks.Patch.Release do
  @moduledoc """
  Prepares Patch for the next release.

  It is expected that the version will be updated in mix.exs **before** running
  this tool.

  This tool will collect some necessary information for the changelog.
  """
  @shortdoc "Prepares Patch for the next release."

  use Mix.Task

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
    summary = get_summary()
    improvements = entries("Improvements")
    features = entries("Features")
    bugfixes = entries("Bugfixes")
    deprecations = entries("Deprecations")
    removals = entries("Removals")

    release = %{
      version: version,
      summary: summary,
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

    changelog_template = Path.expand("./pages/templates/CHANGELOG.eex")
    releases_path = Path.expand("./pages/templates/releases.etf")

    changelog_path = Path.expand("./CHANGELOG.md")
    changelog = EEx.eval_file(changelog_template, releases: releases)

    File.write!(changelog_path, changelog)

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

  def get_summary do
    prompt([:cyan, "Summary", :default_color])
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
