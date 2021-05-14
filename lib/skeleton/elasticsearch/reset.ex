defmodule Skeleton.Elasticsearch.Reset do
  def run(opts) do
    Skeleton.Elasticsearch.Config.get_app_name()
    |> Application.get_env(:elasticsearch_modules)
    |> Enum.each(&do_reset(&1, opts))
  end

  defp do_reset(module, opts) do
    module.drop_index("*")
    module.refresh("*", force: true)

    Skeleton.Elasticsearch.Migrate.run(opts)
  end
end
