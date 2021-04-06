defmodule Mix.Tasks.Skeleton.Elasticsearch.Gen.Migration do
  import Macro, only: [camelize: 1, underscore: 1]
  import Mix.Generator

  @switches [template: :string, prefix: :boolean]
  @aliases [t: :template]

  def run(args) do
    case OptionParser.parse(args, aliases: @aliases, switches: @switches) do
      {opts, [name], []} ->
        elasticsearch = Application.get_env(:skeleton_elasticsearch, :elasticsearch)
        prefix = opts[:prefix]

        path =
          if prefix do
            "priv/elasticsearch/prefix_migrations"
          else
            "priv/elasticsearch/migrations"
          end

        base_name = "#{underscore(name)}.exs"
        file = Path.join(path, "#{timestamp()}_#{base_name}")

        unless File.dir?(path), do: create_directory(path)

        fuzzy_path = Path.join(path, "*_#{base_name}")

        if Path.wildcard(fuzzy_path) != [] do
          Mix.raise(
            "migration can't be created, there is already a migration file with name #{name}."
          )
        end

        assigns = [
          mod: Module.concat([elasticsearch, Migrations, camelize(name)]),
          elasticsearch: elasticsearch,
          prefix: prefix
        ]

        case opts[:template] do
          "create" -> create_file(file, migration_for_create_template(assigns))
          "update" -> create_file(file, migration_for_update_template(assigns))
          _ -> create_file(file, migration_template(assigns))
        end

      {_, _, _} ->
        Mix.raise("expected elasticsearch.gen.migration to receive a name")
    end
  end

  # Timestamp

  defp timestamp do
    {{y, m, d}, {hh, mm, ss}} = :calendar.universal_time()
    "#{y}#{pad(m)}#{pad(d)}#{pad(hh)}#{pad(mm)}#{pad(ss)}"
  end

  # Pad

  defp pad(i) when i < 10, do: <<?0, ?0 + i>>
  defp pad(i), do: to_string(i)

  # Embed template

  embed_template(:migration, """
  defmodule <%= inspect @mod %> do
    import <%= @elasticsearch %>

    def change do
    end
  end
  """)

  embed_template(:migration_for_create, """
  defmodule <%= inspect @mod %> do
    import <%= @elasticsearch %>

    def change<%= if @prefix, do: "([prefix: prefix])" %> do
      data = %{
        settings: %{
          index: %{
            number_of_shards: 3,
            number_of_replicas: 0
          }
        },
        mappings: %{
          dynamic: false,
          properties: %{
            name: %{type: "text"},
            inserted_at: %{type: "date"},
            updated_at: %{type: "date"},
          }
        }
      }

      create_index("index", data<%= if @prefix, do: ", [prefix: prefix]" %>)
    end
  end
  """)

  embed_template(:migration_for_update, """
  defmodule <%= inspect @mod %> do
    import <%= @elasticsearch %>

    def change<%= if @prefix, do: "([prefix: prefix])" %> do
      data = %{
        properties: %{
          new_field: %{type: "text"}
        }
      }

      update_index("index", data<%= if @prefix, do: ", [prefix: prefix]" %>)
    end
  end
  """)
end
