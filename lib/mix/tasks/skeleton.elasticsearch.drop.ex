defmodule Mix.Tasks.Skeleton.Elasticsearch.Drop do
  def run(args) do
    Mix.Task.run("app.start", [])

    {opts, [], []} = OptionParser.parse(args, aliases: [], switches: [])

    Skeleton.Elasticsearch.Drop.run(opts)
  end
end
