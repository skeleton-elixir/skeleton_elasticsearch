defmodule Mix.Tasks.Skeleton.Elasticsearch.Migrate do

  @switches [quiet: :boolean]
  @aliases [q: :quiet]

  def run(args) do
    {opts, [], []} = OptionParser.parse(args, aliases: @aliases, switches: @switches)

    Mix.Task.run("app.start", [])

    elasticsearch = Application.get_env(:skeleton_elasticsearch, :elasticsearch)

    elasticsearch.create_schema_migrations_index()

    last_version = get_last_version(elasticsearch)

    run_migrations(elasticsearch, last_version, opts)
  end

  defp get_last_version(elasticsearch) do
    query = %{
      size: 1,
      query: %{
        match_all: %{}
      },
      sort: [
        %{
          version: :desc
        }
      ]
    }

    "schema_migrations"
    |> elasticsearch.search(query)
    |> get_in(["hits", "hits"])
    |> List.first()
    |> get_in(["_source", "version"])
    |> Kernel.||(0)
  end

  defp run_migrations(elasticsearch, last_version, opts) do
    files =
      "priv/elasticsearch/migrations/*"
      |> Path.wildcard()
      |> Enum.filter(fn file ->
        version = get_version_from_file(file)
        version > last_version
      end)

    if Enum.empty?(files) do
      if !opts[:quiet] do
        Mix.raise("Migrations already up")
      end
    else
      Enum.each(files, fn file ->
        [{module, _}] = Code.require_file(file)

        case module.change() do
          {:ok, _body} ->
            version = get_version_from_file(file)
            elasticsearch.migrate_schema_version(version)

            if !opts[:quiet] do
              Mix.shell().info("#{inspect(module)} migrated")
            end

          {:error, error} ->
            Mix.shell().info("#{inspect(module)} failed")
            Mix.raise(error)
        end
      end)
    end
  end

  # Get version from file

  defp get_version_from_file(file) do
    file
    |> Path.basename("*.exs")
    |> String.split("_")
    |> List.first()
    |> String.to_integer()
  end
end
