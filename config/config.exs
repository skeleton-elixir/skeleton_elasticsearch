use Mix.Config

# Sekeleton
config :skeleton_elasticsearch,
  repo: Skeleton.App.Repo,
  elasticsearch: Skeleton.App.Elasticsearch,
  url: "http://#{System.get_env("ELASTICSEARCH_HOST", "localhost")}:9200",
  refresh: true,
  namespace: :skeleton_elasticsearch,
  suffix: :test

# Repo
config :skeleton_elasticsearch, ecto_repos: [Skeleton.App.Repo]

config :skeleton_elasticsearch, Skeleton.App.Repo,
  adapter: Ecto.Adapters.Postgres,
  pool: Ecto.Adapters.SQL.Sandbox,
  hostname: System.get_env("POSTGRES_HOST", "localhost"),
  database: "skeleton_elasticsearch_test",
  password: System.get_env("POSTGRES_PASSWORD", "123456"),
  username: System.get_env("POSTGRES_USERNAME") || System.get_env("USER") || "postgres"

# Logger
config :logger, :console, level: :error

# Sekeleton
config :skeleton_elasticsearch,
  suffix: :test
