defmodule Skeleton.ElasticsearchTest do
  use Skeleton.Query.TestCase
  import Skeleton.App.Elasticsearch
  alias Skeleton.App.{User, UserIndex}

  describe "index" do
    setup ctx do
      data = %{
        settings: %{index: %{number_of_shards: 1, number_of_replicas: 0}},
        mappings: %{properties: %{name: %{type: "keyword"}}}
      }

      create_index("products", data)

      ctx
    end

    test "get_index" do
      {:ok, %{"skeleton_elasticsearch-products-test" => index}} = get_index("products")

      assert index["settings"]["index"]["number_of_replicas"] == "0"
      assert index["settings"]["index"]["number_of_shards"] == "1"
      assert index["mappings"]["properties"]["name"]["type"] == "keyword"
    end

    test "update_index" do
      data = %{properties: %{color: %{type: "keyword"}}}

      update_index("products", data, [])

      {:ok, %{"skeleton_elasticsearch-products-test" => index}} = get_index("products")

      assert index["settings"]["index"]["number_of_replicas"] == "0"
      assert index["settings"]["index"]["number_of_shards"] == "1"
      assert index["mappings"]["properties"]["name"]["type"] == "keyword"
      assert index["mappings"]["properties"]["color"]["type"] == "keyword"
    end

    # TODO: Verificar problema quando colocamos nome do indice sem o uso do *
    test "truncate_index" do
      create_document("products", 123, %{name: "product name"})

      [res] = search("products", %{query: %{match_all: %{}}})["hits"]["hits"]

      assert res["_id"] == "123"

      truncate_index("*products*")

      {:ok, %{"skeleton_elasticsearch-products-test" => index}} = get_index("products")

      assert index["settings"]["index"]["number_of_replicas"] == "0"
      assert index["settings"]["index"]["number_of_shards"] == "1"
      assert index["mappings"]["properties"]["name"]["type"] == "keyword"

      assert search("products", %{query: %{match_all: %{}}})["hits"]["total"]["value"] == 0

      assert search("schema_migrations", %{query: %{match_all: %{}}})["hits"]["total"]["value"] ==
               1
    end

    test "drop_index" do
      {:ok, %{"skeleton_elasticsearch-products-test" => _}} = get_index("products")

      drop_index("*products*", [])

      assert {:error, "no such index [skeleton_elasticsearch-products-test]"} =
               get_index("products")
    end
  end

  describe "documents" do
    setup ctx do
      user = create_user()

      ctx |> Map.put(:user, user)
    end

    test "create document" do
      {:ok, _user} = create_document("users", "123", %User{name: "user test"})

      [res] = search("users", %{query: %{term: %{_id: 123}}})["hits"]["hits"]
      assert res["_source"]["name"] == "user test"
    end

    test "update document", ctx do
      {:ok, _user} = update_document("users", ctx.user.id, %{ctx.user | name: "user updated"})

      [res] = search("users", %{query: %{term: %{_id: ctx.user.id}}})["hits"]["hits"]
      assert res["_source"]["name"] == "user updated"
      assert res["_source"]["email"] == ctx.user.email
    end

    test "update partial document", ctx do
      {:ok, _user} = update_document("users", ctx.user.id, %{name: "user updated"})

      [res] = search("users", %{query: %{term: %{_id: ctx.user.id}}})["hits"]["hits"]
      assert res["_source"]["name"] == "user updated"
      assert res["_source"]["email"] == ctx.user.email
    end

    test "update document by script", ctx do
      data = %{
        source: """
          ctx._source.name = params.name;
        """,
        lang: "painless",
        params: %{
          name: "name updated"
        }
      }

      {:ok, _user} = update_document_by_script("users", ctx.user.id, data)

      [res] = search("users", %{query: %{term: %{_id: ctx.user.id}}})["hits"]["hits"]
      assert res["_source"]["name"] == "name updated"
      assert res["_source"]["email"] == ctx.user.email
    end

    test "update documents by query", ctx do
      term = %{term: %{_id: ctx.user.id}}

      script = %{
        source: """
          ctx._source = params;
        """,
        lang: "painless",
        params: %{ctx.user | name: "name updated"}
      }

      {:ok, _user} = update_documents_by_query("users", term, script)

      [res] = search("users", %{query: term})["hits"]["hits"]
      assert res["_source"]["name"] == "name updated"
      assert res["_source"]["email"] == ctx.user.email
    end

    test "delete document", ctx do
      {:ok, _user} = delete_document("users", ctx.user.id)
      assert [] = search("users", %{query: %{term: %{_id: ctx.user.id}}})["hits"]["hits"]
    end

    test "delete documents by query", ctx do
      term = %{term: %{_id: ctx.user.id}}
      {:ok, _user} = delete_documents_by_query("users", term)
      assert [] = search("users", %{query: term})["hits"]["hits"]
    end
  end

  describe "bulk" do
    test "bulk" do
      data = [
        %{index: %{_id: "1"}},
        %{name: "user 1"},
        %{index: %{_id: "2"}},
        %{name: "user 2"}
      ]

      bulk("users", data)

      [res] = search("users", %{query: %{term: %{_id: 1}}})["hits"]["hits"]
      assert res["_source"]["name"] == "user 1"

      [res] = search("users", %{query: %{term: %{_id: 2}}})["hits"]["hits"]
      assert res["_source"]["name"] == "user 2"
    end

    test "sync" do
      user1 = create_user(name: "User 1")
      user2 = create_user(name: "User 2")
      create_user(name: "User 3")

      :ok = sync("users", User, [], :id, &%{&1 | name: "#{&1.name} updated"})

      users = search("users", %{query: %{match_all: %{}}})["hits"]["hits"]
      assert hd(users)["_source"]["name"] == "#{user1.name} updated"
      assert length(users) == 3

      Repo.delete(user1)

      :ok = sync("users", User, [], :id, & &1)

      users = search("users", %{query: %{match_all: %{}}})["hits"]["hits"]
      assert hd(users)["_source"]["name"] == user2.name
      assert length(users) == 2
    end

    test "sync without deleting outdated" do
      user1 = create_user(name: "User 1")
      create_user(name: "User 2")
      create_user(name: "User 3")

      :ok = sync("users", User, [], :id, & &1, [], delete_outdated: false)

      users = search("users", %{query: %{match_all: %{}}})["hits"]["hits"]
      assert length(users) == 3

      Repo.delete(user1)

      :ok = sync("users", User, [], :id, & &1, [], delete_outdated: false)

      users = search("users", %{query: %{match_all: %{}}})["hits"]["hits"]
      assert length(users) == 3
    end
  end

  describe "search" do
    test "search" do
      user1 = create_user(name: "User 1")
      create_user(name: "User 2")

      [res] = search("users", %{query: %{term: %{_id: user1.id}}})["hits"]["hits"]
      assert res["_source"]["name"] == "User 1"
    end
  end

  describe "refres" do
    test "refresh" do
      {:ok, %{status_code: 200}} = refresh("users", force: true)
      {:ok, %{status_code: 404}} = refresh("inexistent", force: true)
    end
  end

  defp create_user(params \\ %{}) do
    user =
      %User{
        id: params[:id],
        name: params[:name] || "Name #{params[:id]}",
        email: "email-#{params[:id]}@email.com",
        admin: false
      }
      |> change(params)
      |> Repo.insert!()

    UserIndex.create(user)

    user
  end

  describe "Index name" do
    test "returns index name without prefix" do
      assert index_name("users") == "skeleton_elasticsearch-users-test"
    end

    test "returns index name with prefix" do
      assert index_name("users", prefix: "tenant") == "skeleton_elasticsearch-tenant-users-test"
    end
  end
end
