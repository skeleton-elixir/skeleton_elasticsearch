defmodule Skeleton.App.Elasticsearch.Migrations.AddTasks do
  import Elixir.Skeleton.App.Elasticsearch

  def change([prefix: prefix]) do
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
          last_synced_at: %{type: "date"},
          inserted_at: %{type: "date"},
          updated_at: %{type: "date"},
        }
      }
    }

    create_index("tasks", data, [prefix: prefix])
  end
end
