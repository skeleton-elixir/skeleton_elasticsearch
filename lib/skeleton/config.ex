defmodule Skeleton.Elasticsearch.Config do
  def elasticsearch, do: config(:elasticsearch)
  def url, do: config(:url)
  def refresh, do: config(:refresh)
  def sort_param, do: config(:sort_param, "sort_by")
  def debug, do: config(:debug, false)

  def config(key, default \\ nil) do
    Application.get_env(:skeleton_elasticsearch, key, default)
  end
end
