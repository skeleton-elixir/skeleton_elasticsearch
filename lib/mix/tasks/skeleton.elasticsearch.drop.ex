defmodule Mix.Tasks.Skeleton.Elasticsearch.Drop do
  def run(_args) do
    Mix.Task.run("app.start", [])

    Mix.Project.config()[:app]
    |> Application.get_env(:elasticsearch_modules)
    |> Enum.each(&do_drop/1)
  end

  defp do_drop(module) do
    module.drop_index("*")
  end
end
