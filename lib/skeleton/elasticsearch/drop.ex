defmodule Skeleton.Elasticsearch.Drop do
  def run(_opts) do
    Skeleton.Elasticsearch.Config.get_app_name()
    |> Application.get_env(:elasticsearch_modules)
    |> Enum.each(&do_drop/1)
  end

  defp do_drop(module) do
    module.drop_index("*")
  end
end
