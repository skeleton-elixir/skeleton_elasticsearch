use Mix.Config

# Repo
config :skeleton_elasticsearch, ecto_repos: [Skeleton.App.Repo]

config :skeleton_elasticsearch, Skeleton.App.Repo,
  adapter: Ecto.Adapters.Postgres,
  pool: Ecto.Adapters.SQL.Sandbox,
  database: "skeleton_elasticsearch_test",
  username: System.get_env("SKELETON_ELASTICSEARCH_DB_USER") || System.get_env("USER") || "postgres"

# Logger
config :logger, :console, level: :error

# Sekeleton
config :skeleton_elasticsearch,
  repo: Skeleton.App.Repo,
  elasticsearch: Skeleton.App.Elasticsearch,
  url: "http://localhost:9200",
  refresh: true,
  prefix: :skeleton_elasticsearch_test
