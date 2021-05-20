defmodule Mix.Tasks.Skeleton.Elasticsearch.Sync do
  def run(args) do
    Mix.Task.run("app.start", [])

    {_opts, names, []} = OptionParser.parse(args, aliases: [], switches: [])

    Skeleton.Elasticsearch.Sync.run(names)
  end
end
