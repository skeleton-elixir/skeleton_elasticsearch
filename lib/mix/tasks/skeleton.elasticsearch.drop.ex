defmodule Mix.Tasks.Skeleton.Elasticsearch.Drop do
  def run(_args) do
    Mix.Task.run("app.start", [])

    elasticsearch = Application.get_env(:skeleton_elasticsearch, :elasticsearch)

    elasticsearch.drop_index("*")
  end
end
