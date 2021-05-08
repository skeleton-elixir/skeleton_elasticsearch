defmodule Skeleton.Elasticsearch.Config do
  def url(conf), do: config(conf, :url)
  def refresh(conf), do: config(conf, :refresh)
  def sort_param(conf), do: config(conf, :sort_param, "sort_by")
  def aggs_param(conf), do: config(conf, :aggs_param, "aggs_by")
  def namespace(conf), do: config(conf, :namespace, "app")
  def prefix(conf), do: config(conf, :prefix, nil)
  def suffix(conf), do: config(conf, :suffix, nil)
  def priv(conf), do: config(conf, :priv, "priv/elasticsearch")
  def repo(conf), do: config(conf, :repo, nil)
  def start_query(conf), do: config(conf, :start_query, %{})
  def size(conf), do: config(conf, :size, 10)
  def last_synced_at_field(conf), do: config(conf, :last_synced_at_field, "last_synced_at")
  def sync_modules(conf), do: config(conf, :sync_modules, [])
  def sync_interval(conf), do: config(conf, :sync_interval, 300)
  def sync_size(conf), do: config(conf, :sync_size, 500)

  def config(module, key, default \\ nil) do
    module[key] || default
  end

  def get_module_config(otp_app, module) do
    Application.get_env(otp_app, module)
  end
end
