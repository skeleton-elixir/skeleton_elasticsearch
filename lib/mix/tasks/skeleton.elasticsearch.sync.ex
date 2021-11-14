defmodule Mix.Tasks.Skeleton.Elasticsearch.Sync do
  @moduledoc """
  Elasticsearhc sync task
  """

  def run(args) do
    Mix.Task.run("app.start", [])

    {_opts, names, []} = OptionParser.parse(args, aliases: [], switches: [])

    Skeleton.Elasticsearch.Sync.run(names)
  end
end
