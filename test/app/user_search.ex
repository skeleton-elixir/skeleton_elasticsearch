defmodule Skeleton.App.UserSearch do
  use Skeleton.App.Search, index: "users"

  # Filters

  def filter_by(query, {"id", id}, _params) do
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

  def filter_by(query, {"name", name}, _params) do
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

  # Sort By

  def sort_by(query, "inserted_at_desc", _params) do
    add_query(query, %{
      sort: [%{inserted_at: "desc"}]
    })
  end

  def sort_by(query, "random", %{"random_seed" => seed}) do
    add_query(query, %{
      query: %{
        function_score: %{
          random_score: %{
            seed: seed,
            field: "_seq_no"
          }
        }
      }
    })
  end

  # Aggs

  def aggs_by(query, "id", _params) do
    add_query(query, %{
      aggs: %{
        id_term: %{
          terms: %{
            size: 10,
            field: "_id"
          }
        }
      }
    })
  end
end
