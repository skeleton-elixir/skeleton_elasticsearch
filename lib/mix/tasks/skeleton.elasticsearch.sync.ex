defmodule Mix.Tasks.Skeleton.Elasticsearch.Sync do
  def run(args) do
    Mix.Task.run("app.start", [])

    {opts, [], []} = OptionParser.parse(args, aliases: [], switches: [])

    Skeleton.Elasticsearch.Sync.run(opts)
  end
end
