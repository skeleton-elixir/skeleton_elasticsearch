defmodule Skeleton.UserSearchTest do
  use Skeleton.Query.TestCase

  alias Skeleton.App.{User, UserIndex, UserSearch}

  setup ctx do
    user = create_user()

    ctx
    |> Map.put(:user, user)
  end

  # Query all

  test "search all filtering by id", ctx do
    [res] = UserSearch.search(%{id: ctx.user.id})["hits"]["hits"]
    assert res["_id"] == ctx.user.id
  end

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

    UserIndex.create(:user, user)

    user
  end
end
