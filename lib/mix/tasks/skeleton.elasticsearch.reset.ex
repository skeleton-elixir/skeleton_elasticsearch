defmodule Mix.Tasks.Skeleton.Elasticsearch.Reset do
  def run(args) do
    Mix.Task.run("app.start", [])

    {opts, [], []} = OptionParser.parse(args, aliases: [], switches: [])

    Skeleton.Elasticsearch.Reset.run(opts)
  end
end
