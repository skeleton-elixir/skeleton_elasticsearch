defmodule Skeleton.App.UserSearch do
  use Skeleton.Elasticsearch.Search, index: "users"

  # Filters

  def filter_by(query, {:id, id}, _params) do
    add_query(query, %{
      query: %{
        bool: %{
          must: [
            %{
              term: %{_id: id}
            }
          ]
        }
      }
    })
  end

  def filter_by(query, {:name, name}, _params) do
    add_query(query, %{
      query: %{
        bool: %{
          must: [
            %{
              match: %{name: name}
            }
          ]
        }
      }
    })
  end
end
