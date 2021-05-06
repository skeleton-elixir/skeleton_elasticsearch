defmodule Mix.Tasks.Skeleton.Elasticsearch.Migrate do
  @switches [quiet: :boolean, prefix: :string]
  @aliases [q: :quiet, p: :prefix]

  def run(args) do
    Mix.Task.run("app.start", [])

    {opts, [], []} = OptionParser.parse(args, aliases: @aliases, switches: @switches)

    Mix.Project.config()[:app]
    |> Application.get_env(:elasticsearch_modules)
    |> Enum.each(&do_migrate(&1, opts))
  end

  defp do_migrate(module, opts) do
    module.migrate(opts)
  end
end
