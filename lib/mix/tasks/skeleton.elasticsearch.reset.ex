defmodule Mix.Tasks.Skeleton.Elasticsearch.Reset do
  def run(args) do
    Mix.Task.run("app.start", [])

    Mix.Project.config()[:app]
    |> Application.get_env(:elasticsearch_modules)
    |> Enum.each(&do_reset(&1, args))
  end

  defp do_reset(module, args) do
    module.drop_index("*")
    module.refresh("*", force: true)

    Mix.Tasks.Skeleton.Elasticsearch.Migrate.run(args)
  end
end
