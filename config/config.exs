import Config

# Sekeleton
config :skeleton_elasticsearch, elasticsearch_modules: [Skeleton.App.Elasticsearch]

config :skeleton_elasticsearch, Skeleton.App.Elasticsearch,
  repo: Skeleton.App.Repo,
  url: "http://#{System.get_env("ELASTICSEARCH_HOST", "localhost")}:9200",
  refresh: true,
  start_query: %{
    size: 10
  },
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
