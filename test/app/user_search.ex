defmodule Skeleton.App.UserSearch do
  @moduledoc false

  use Skeleton.App.Search, index: "users"

  def compose(query, {"id", id}, _params) do
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

  def compose(query, {"name", name}, _params) do
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

  def compose(query, {"sort_by", "inserted_at_desc"}, _params) do
    add_query(query, %{
      sort: [%{inserted_at: "desc"}]
    })
  end

  def compose(query, {"sort_by", "name"}, _params) do
    add_query(query, %{
      sort: [%{name: "asc"}]
    })
  end

  def compose(query, {"sort_by", "random"}, %{"random_seed" => seed}) do
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

  def compose(query, {"aggs_by", "id"}, _params) do
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

  def compose(query, {"aggs_by", "admin"}, _params) do
    add_query(query, %{
      aggs: %{
        admin_term: %{
          terms: %{
            size: 10,
            field: "admin"
          }
        }
      }
    })
  end
end
