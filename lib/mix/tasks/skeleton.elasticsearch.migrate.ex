defmodule Mix.Tasks.Skeleton.Elasticsearch.Migrate do
  @switches [quiet: :boolean, prefix: :string]
  @aliases [q: :quiet, p: :prefix]

  def run(args) do
    Mix.Task.run("app.start", [])

    {opts, [], []} = OptionParser.parse(args, aliases: @aliases, switches: @switches)

    elasticsearch = Application.get_env(:skeleton_elasticsearch, :elasticsearch)
    elasticsearch.migrate(opts)
  end
end
