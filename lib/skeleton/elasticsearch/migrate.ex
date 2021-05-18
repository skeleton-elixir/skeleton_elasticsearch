defmodule Skeleton.Elasticsearch.Migrate do
  alias Skeleton.Elasticsearch.Config

  def run(opts) do
    Config.get_app_name()
    |> Application.get_env(:elasticsearch_modules)
    |> Enum.each(&do_migrate(&1, opts))
  end

  defp do_migrate(module, opts) do
    prefixes =
      if prefix = opts[:prefix] do
        [prefix]
      else
        [nil] ++ module.prefixes()
      end

    Enum.each(prefixes, fn prefix ->
      module.create_schema_migrations_index(prefix: prefix)
      last_version = get_last_version(module, prefix: prefix)

      try do
        run_migrations(module, last_version, opts ++ [prefix: prefix])
      rescue
        e in [RuntimeError, Mix.Error] -> IO.inspect(e.message <> " in #{prefix || "default"}")
        e -> IO.inspect(e <> " in #{prefix || "default"}")
      end
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
              IO.inspect("#{inspect(module)} migrated")
            end

          {:error, error} ->
            IO.inspect("#{inspect(module)} failed")
            raise(error)
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
