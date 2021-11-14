defmodule SkeletonElasticsearch.MixProject do
  use Mix.Project

  @version "1.2.9"
  @source_url "https://github.com/skeleton-elixir/skeleton_elasticsearch"
  @maintainers [
    "Diego Nogueira",
    "Jhonathas Matos"
  ]

  def project do
    [
      name: "SkeletonElasticsearch",
      app: :skeleton_elasticsearch,
      version: @version,
      elixir: "~> 1.8",
      elixirc_paths: elixirc_paths(Mix.env()),
      package: package(),
      source_url: @source_url,
      aliases: aliases(),
      maintainers: @maintainers,
      description: description(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :eex]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:elastix, "~> 0.9.0"},
      {:jason, "~> 1.2"},
      {:poison, "~> 3.1"},
      {:ecto_sql, "~> 3.0", only: :test},
      {:postgrex, ">= 0.0.0", only: :test},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.10", only: :test}
    ]
  end

  defp description() do
    "O Skeleton Elasticsearch ajuda a criar composes para queries feitas usando o Elastix"
  end

  defp elixirc_paths(:test), do: ["lib", "test/app"]
  defp elixirc_paths(_), do: ["lib"]

  defp package do
    [
      maintainers: @maintainers,
      licenses: ["MIT"],
      files: ~w(lib CHANGELOG.md LICENSE mix.exs README.md),
      links: %{
        "GitHub" => @source_url,
        "Changelog" => "#{@source_url}/blob/master/CHANGELOG.md"
      }
    ]
  end

  defp aliases do
    [
      test: [
        "ecto.create --quiet",
        "ecto.migrate --quiet",
        "skeleton.elasticsearch.reset --quiet",
        "test"
      ]
    ]
  end
end
