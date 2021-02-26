defmodule Mix.Tasks.Skeleton.Elasticsearch.Reset do
  def run(args) do
    Mix.Task.run("app.start", [])

    elasticsearch = Application.get_env(:skeleton_elasticsearch, :elasticsearch)

    elasticsearch.drop_index("*")
    elasticsearch.refresh("*", force: true)

    Mix.Tasks.Skeleton.Elasticsearch.Migrate.run(args)
  end
end
