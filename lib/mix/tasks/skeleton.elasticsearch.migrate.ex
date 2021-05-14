defmodule Mix.Tasks.Skeleton.Elasticsearch.Migrate do
  @switches [quiet: :boolean, prefix: :string]
  @aliases [q: :quiet, p: :prefix]

  def run(args) do
    Mix.Task.run("app.start", [])

    {opts, [], []} = OptionParser.parse(args, aliases: @aliases, switches: @switches)

    Skeleton.Elasticsearch.Migrate.run(opts)
  end
end
