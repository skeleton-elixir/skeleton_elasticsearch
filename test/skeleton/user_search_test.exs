defmodule Skeleton.UserSearchTest do
  use Skeleton.Query.TestCase

  alias Skeleton.App.{User, UserIndex, UserSearch}

  setup ctx do
    user = create_user()

    ctx
    |> Map.put(:user, user)
  end

  # Build Query

  test "build query", ctx do
    res_query =
      UserSearch.build_query(
        %{id: ctx.user.id, sort_by: [:inserted_at_desc], aggs_by: ["id"]},
        from: 1,
        size: 1
      )

    query = %{
      aggs: %{id_term: %{terms: %{field: "_id", size: 10}}},
      from: 1,
      size: 1,
      sort: [%{inserted_at: "desc"}],
      query: %{bool: %{must: [%{term: %{_id: ctx.user.id}}]}}
    }

    assert res_query == query
  end

  # Search from query

  test "search from query", ctx do
    query = UserSearch.build_query(%{}, size: 1)
    [%{"_source" => source}] = UserSearch.search_from_query(query)["hits"]["hits"]
    assert source["email"] == ctx.user.email
  end

  # Query all

  test "search all filtering by id", ctx do
    [res] = UserSearch.search(%{"id" => ctx.user.id})["hits"]["hits"]
    assert res["_id"] == ctx.user.id
  end

  test "search all" do
    create_user()
    users = UserSearch.search(%{})["hits"]["hits"]
    assert length(users) == 2
  end

  test "search all with size" do
    create_user()
    create_user()

    users = UserSearch.search(%{}, size: 1)["hits"]["hits"]
    assert length(users) == 1
  end

  test "search all with from" do
    create_user()
    last_user = create_user()

    users = UserSearch.search(%{}, from: 1)["hits"]["hits"]
    assert length(users) == 2
    assert List.last(users)["_id"] == last_user.id
  end

  test "search all with size and from" do
    user = create_user()
    create_user()

    [indexed_user] = UserSearch.search(%{}, from: 1, size: 1)["hits"]["hits"]
    assert indexed_user["_id"] == user.id
  end

  # Sort By

  test "search all and sort by inserted at desc" do
    future_datetime =
      NaiveDateTime.utc_now()
      |> NaiveDateTime.add(10)
      |> NaiveDateTime.truncate(:second)

    user = create_user(inserted_at: future_datetime)
    create_user()

    [indexed_user | _] = UserSearch.search(%{"sort_by" => ["inserted_at_desc"]})["hits"]["hits"]
    assert indexed_user["_id"] == user.id
  end

  test "search all and sort by random score" do
    create_user()

    users =
      UserSearch.search(%{
        "name" => "Name",
        "random_seed" => "1234",
        "sort_by" => ["random"]
      })["hits"]["hits"]

    assert length(users) == 2
  end

  # Aggs

  test "search all with aggs", ctx do
    res = UserSearch.search(%{"aggs_by" => [:id]}, size: 0)
    assert ctx.user.id == get_in(res, ["aggregations", "id_term", "buckets", Access.at(0), "key"])
  end

  # Allow params

  test "allowing params" do
    query =
      UserSearch.build_query(%{"id" => "1", "name" => "full name", admin: true},
        allow: [:id]
      )

    assert query == %{query: %{bool: %{must: [%{term: %{_id: "1"}}]}}, size: 10}

    query =
      UserSearch.build_query(%{"id" => "1", "name" => "full name", admin: true},
        allow: [:id, :name]
      )

    assert query == %{
             query: %{bool: %{must: [%{term: %{_id: "1"}}, %{match: %{name: "full name"}}]}},
             size: 10
           }
  end

  # Deny params

  test "denying params" do
    query =
      UserSearch.build_query(%{"id" => "1", "name" => "full name", admin: true},
        deny: [:id]
      )

    assert query == %{query: %{bool: %{must: [%{match: %{name: "full name"}}]}}, size: 10}

    query =
      UserSearch.build_query(%{"id" => "1", "name" => "full name", admin: true},
        deny: [:id, :name]
      )

    assert query == %{size: 10}
  end

  # Allow sort by params

  test "allowing sort by params" do
    query =
      UserSearch.build_query(
        %{
          "id" => "1",
          "name" => "full name",
          admin: true,
          sort_by: [
            "inserted_at_desc",
            "name"
          ]
        },
        allow: [:id, sort_by: [:name]]
      )

    assert query == %{
             query: %{bool: %{must: [%{term: %{_id: "1"}}]}},
             size: 10,
             sort: [%{name: "asc"}]
           }

    query =
      UserSearch.build_query(
        %{"id" => "1", "name" => "full name", admin: true, sort_by: ["inserted_at_desc", "name"]},
        allow: [:id, :name, sort_by: [:inserted_at_desc, :name]]
      )

    assert query == %{
             query: %{bool: %{must: [%{term: %{_id: "1"}}, %{match: %{name: "full name"}}]}},
             size: 10,
             sort: [%{inserted_at: "desc"}, %{name: "asc"}]
           }
  end

  # Deny sort by params

  test "denying sort by params" do
    query =
      UserSearch.build_query(
        %{
          "id" => "1",
          "name" => "full name",
          admin: true,
          sort_by: [
            "inserted_at_desc",
            "name"
          ]
        },
        deny: [:name, sort_by: [:inserted_at_desc]]
      )

    assert query == %{
             query: %{bool: %{must: [%{term: %{_id: "1"}}]}},
             size: 10,
             sort: [%{name: "asc"}]
           }

    query =
      UserSearch.build_query(
        %{"id" => "1", "name" => "full name", admin: true, sort_by: ["inserted_at_desc", "name"]},
        allow: [:id, :name, sort_by: [:inserted_at_desc, :name]]
      )

    assert query == %{
             query: %{bool: %{must: [%{term: %{_id: "1"}}, %{match: %{name: "full name"}}]}},
             size: 10,
             sort: [%{inserted_at: "desc"}, %{name: "asc"}]
           }
  end

  # Allow aggs by params

  test "allowing aggs by params" do
    query =
      UserSearch.build_query(
        %{
          "id" => "1",
          "name" => "full name",
          sort_by: [
            "name"
          ],
          aggs_by: ["id", "admin"]
        },
        allow: [:id, sort_by: [:name], aggs_by: [:id]]
      )

    assert query == %{
             aggs: %{id_term: %{terms: %{field: "_id", size: 10}}},
             query: %{bool: %{must: [%{term: %{_id: "1"}}]}},
             size: 10,
             sort: [%{name: "asc"}]
           }

    query =
      UserSearch.build_query(
        %{
          "id" => "1",
          "name" => "full name",
          sort_by: [
            "name"
          ],
          aggs_by: ["id", "admin"]
        },
        allow: [:id, sort_by: [:name], aggs_by: [:id, "admin"]]
      )

    assert query == %{
             aggs: %{
               admin_term: %{terms: %{field: "admin", size: 10}},
               id_term: %{terms: %{field: "_id", size: 10}}
             },
             query: %{bool: %{must: [%{term: %{_id: "1"}}]}},
             size: 10,
             sort: [%{name: "asc"}]
           }
  end

  # Deny aggs by params

  test "denying aggs by params" do
    query =
      UserSearch.build_query(
        %{
          "id" => "1",
          "name" => "full name",
          sort_by: [
            "name"
          ],
          aggs_by: [
            "id",
            "admin"
          ]
        },
        deny: [:name, aggs_by: [:admin]]
      )

    assert query == %{
             aggs: %{id_term: %{terms: %{field: "_id", size: 10}}},
             query: %{bool: %{must: [%{term: %{_id: "1"}}]}},
             size: 10,
             sort: [%{name: "asc"}]
           }

    query =
      UserSearch.build_query(
        %{"id" => "1", "name" => "full name", sort_by: ["name"], aggs_by: [:name]},
        deny: [:id, :name, sort_by: [:name], aggs_by: [:name]]
      )

    assert query == %{size: 10}
  end

  # Helpers

  defp create_user(params \\ %{}) do
    user =
      %User{
        id: params[:id],
        name: "Name #{params[:id]}",
        email: "email-#{params[:id]}@email.com",
        admin: false
      }
      |> change(params)
      |> Repo.insert!()

    UserIndex.create(user)

    user
  end
end
