defmodule Skeleton.App.Elasticsearch.Migrations.CreateUsers do
  import Elixir.Skeleton.App.Elasticsearch

  def change do
    data = %{
      settings: %{
        index: %{
          number_of_shards: 1,
          number_of_replicas: 0
        }
      },
      mappings: %{
        dynamic: false,
        properties: %{
          name: %{
            type: "text",
            analyzer: "brazilian"
          },
          email: %{type: "keyword"},
          admin: %{type: "boolean"},
          inserted_at: %{type: "date"},
          updated_at: %{type: "date"},
          last_synced_at: %{type: "date"}
        }
      }
    }

    create_index("users", data)
  end
end
