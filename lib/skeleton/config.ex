defmodule Skeleton.Elasticsearch.Config do
  def elasticsearch, do: config(:elasticsearch)
  def url, do: config(:url)
  def refresh, do: config(:refresh)
  def sort_param, do: config(:sort_param, "sort_by")
  def prefix, do: config(:prefix, :dev)
  def priv, do: config(:priv, "priv/elasticsearch")
  def repo, do: config(:repo, nil)
  def last_synced_at_field, do: config(:last_synced_at_field, "last_synced_at")

  def config(key, default \\ nil) do
    Application.get_env(:skeleton_elasticsearch, key, default)
  end
end
