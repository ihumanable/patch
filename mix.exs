defmodule Patch.MixProject do
  use Mix.Project

  def project do
    [
      app: :patch,
      version: "0.5.0",
      elixir: "~> 1.7",
      erlc_paths: erlc_paths(Mix.env()),
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:meck, "~> 0.9.2"}
    ]
  end

  # Specifies which erlang paths to compile per environemnt
  defp erlc_paths(env) when env in [:dev, :test], do: ["test/support"]
  defp erlc_paths(_), do: []

  # Specifies which elixir paths to compile per environment.
  defp elixirc_paths(env) when env in [:dev, :test], do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp docs do
    [
      name: "Patch",
      extras: ["pages/README.md", "pages/CHANGELOG.md"],
      main: "readme",
      source_url: "https://github.com/ihumanable/patch"
    ]
  end

  defp package() do
    [
      description: "Ergonomic Patching for Elixir Unit Testing",
      licenses: ["MIT"],
      maintainers: ["Matt Nowack"],
      links: %{
        "GitHub" => "https://github.com/ihumanable/patch"
      }
    ]
  end
end
