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

  # Aggs

  test "search all with aggs", ctx do
    res = UserSearch.search(%{"aggs_by" => [:id]}, size: 0)
    assert ctx.user.id == get_in(res, ["aggregations", "id_term", "buckets", Access.at(0), "key"])
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
