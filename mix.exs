defmodule Patch.MixProject do
  use Mix.Project

  def project do
    [
      app: :patch,
      version: "0.14.0",
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
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  # Specifies which erlang paths to compile per environment
  defp erlc_paths(:test), do: ["test/support"]
  defp erlc_paths(_), do: []

  # Specifies which elixir paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp docs do
    [
      name: "Patch",
      extras: [
        "README.md",
        "pages/cheatsheet.cheatmd",
        "pages/super-powers.md",
        "pages/guide-book/01-introduction.md",
        "pages/guide-book/02-patching.md",
        "pages/guide-book/03-mock-values.md",
        "pages/guide-book/04-spies-and-fakes.md",
        "pages/guide-book/05-processes.md",
        "CHANGELOG.md"
      ],
      groups_for_extras: [
        "Guide Book": [
          "pages/guide-book/01-introduction.md",
          "pages/guide-book/02-patching.md",
          "pages/guide-book/03-mock-values.md",
          "pages/guide-book/04-spies-and-fakes.md",
          "pages/guide-book/05-processes.md"
        ]
      ],
      groups_for_modules: [
        "Developer Interface": [
          Patch
        ],
        Listener: [
          Patch.Listener,
          Patch.Listener.Supervisor
        ],
        Mock: [
          Patch.Mock,
          Patch.Mock.History,
          Patch.Mock.History.Tagged,
          Patch.Mock.Naming,
          Patch.Mock.Server,
          Patch.Mock.Supervisor
        ],
        "Mock Code": [
          Patch.Mock.Code,
          Patch.Mock.Code.Freezer,
          Patch.Mock.Code.Generate,
          Patch.Mock.Code.Query,
          Patch.Mock.Code.Transform,
          Patch.Mock.Code.Unit
        ],
        "Mock Code Generators": [
          Patch.Mock.Code.Generators.Delegate,
          Patch.Mock.Code.Generators.Facade,
          Patch.Mock.Code.Generators.Frozen,
          Patch.Mock.Code.Generators.Original
        ],
        "Mock Code Queries": [
          Patch.Mock.Code.Queries.Exports,
          Patch.Mock.Code.Queries.Functions
        ],
        "Mock Code Transforms": [
          Patch.Mock.Code.Transforms.Clean,
          Patch.Mock.Code.Transforms.Export,
          Patch.Mock.Code.Transforms.Filter,
          Patch.Mock.Code.Transforms.Remote,
          Patch.Mock.Code.Transforms.Rename,
          Patch.Mock.Code.Transforms.Reroute
        ],
        "Mock Values": [
          Patch.Mock.Value,
          Patch.Mock.Values.Callable,
          Patch.Mock.Values.CallableStack,
          Patch.Mock.Values.Cycle,
          Patch.Mock.Values.Raises,
          Patch.Mock.Values.Scalar,
          Patch.Mock.Values.Sequence,
          Patch.Mock.Values.Throws
        ],
        Utilities: [
          Patch.Access,
          Patch.Apply,
          Patch.Assertions,
          Patch.Macro,
          Patch.Reflection,
          Patch.Supervisor
        ]
      ],
      main: "readme",
      source_ref: "master",
      source_url: "https://github.com/ihumanable/patch"
    ]
  end

  defp package() do
    [
      description: "Ergonomic Mocking for Elixir Unit Testing",
      licenses: ["MIT"],
      maintainers: ["Matt Nowack"],
      links: %{
        "GitHub" => "https://github.com/ihumanable/patch"
      }
    ]
  end
end
