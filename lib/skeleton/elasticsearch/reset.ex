defmodule Skeleton.Elasticsearch.Reset do
  @moduledoc false

  alias Skeleton.Elasticsearch.Config

  def run(opts) do
    Config.get_app_name()
    |> Application.get_env(:elasticsearch_modules)
    |> Enum.each(&do_reset(&1, opts))
  end

  defp do_reset(module, opts) do
    module.drop_index("*")
    module.refresh("*", force: true)

    Skeleton.Elasticsearch.Migrate.run(opts)
  end
end
