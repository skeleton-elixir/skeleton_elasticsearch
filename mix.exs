defmodule Skeleton.MixProject do
  use Mix.Project

  @version "1.0.0"
  @url "https://github.com/skeleton-elixir/skeleton_elasticsearch"
  @maintainers [
    "Diego Nogueira",
    "Jhonathas Matos"
  ]

  def project do
    [
      name: "SkeletonElasticsearch",
      app: :skeleton_elasticsearch,
      version: @version,
      elixir: "~> 1.10",
      elixirc_paths: elixirc_paths(Mix.env()),
      package: package(),
      source_url: @url,
      aliases: aliases(),
      maintainers: @maintainers,
      description: "Elixir structure",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:elastix, github: "werbitzky/elastix"},
      {:jason, "~> 1.2"},
      {:ecto_sql, "~> 3.0", only: :test},
      {:postgrex, ">= 0.0.0", only: :test},
      {:poison, "~> 3.1"}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp package do
    [
      maintainers: @maintainers,
      licenses: ["MIT"],
      links: %{github: @url},
      files: ~w(lib) ++ ~w(CHANGELOG.md LICENSE mix.exs README.md)
    ]
  end

  defp aliases do
    [
      test: [
        "ecto.create --quiet",
        "ecto.migrate --quiet",
        "skeleton.elasticsearch.migrate --quiet",
        "test"
      ]
    ]
  end
end
