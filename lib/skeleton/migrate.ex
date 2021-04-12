defmodule Skeleton.Elasticsearch.Migrate do
  def run(opts) do
    elasticsearch = Application.get_env(:skeleton_elasticsearch, :elasticsearch)

    prefixes =
      if prefix = opts[:prefix] do
        [prefix]
      else
        [nil] ++ elasticsearch.prefixes()
      end

    Enum.each(prefixes, fn prefix ->
      elasticsearch.create_schema_migrations_index(prefix: prefix)
      last_version = get_last_version(elasticsearch, prefix: prefix)
      run_migrations(elasticsearch, last_version, opts ++ [prefix: prefix])
    end)
  end

  defp get_last_version(elasticsearch, opts) do
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
    |> elasticsearch.search(query, opts)
    |> get_in(["hits", "hits"])
    |> List.first()
    |> get_in(["_source", "version"])
    |> Kernel.||(0)
  end

  defp run_migrations(elasticsearch, last_version, opts) do
    path =
      if opts[:prefix] do
        "priv/elasticsearch/prefix_migrations/*"
      else
        "priv/elasticsearch/migrations/*"
      end

    files =
      path
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
        file = Path.expand(file)
        [{module, _}] = Code.require_file(file)

        changed =
          if prefix = opts[:prefix] do
            module.change(prefix: prefix)
          else
            module.change()
          end

        Code.unrequire_files([file])
        :code.purge(module)
        :code.delete(module)

        case changed do
          {:ok, _body} ->
            version = get_version_from_file(file)
            elasticsearch.migrate_schema_version(version, opts)

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
