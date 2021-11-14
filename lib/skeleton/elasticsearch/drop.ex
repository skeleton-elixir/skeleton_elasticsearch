defmodule Skeleton.Elasticsearch.Drop do
  @moduledoc """
  Skeleton drop index
  """

  alias Skeleton.Elasticsearch.Config

  def run(_opts) do
    Config.get_app_name()
    |> Application.get_env(:elasticsearch_modules)
    |> Enum.each(&do_drop/1)
  end

  defp do_drop(module) do
    module.drop_index("*")
  end
end
