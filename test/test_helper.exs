defmodule Skeleton.Query.TestCase do
  use ExUnit.CaseTemplate

  using opts do
    quote do
      use ExUnit.Case, unquote(opts)
      import Ecto.Changeset
      alias Skeleton.App.Repo
    end
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Skeleton.App.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Skeleton.App.Repo, {:shared, self()})
    {:ok, _} = Skeleton.App.Elasticsearch.truncate_index("*")
  end
end

Skeleton.App.Repo.start_link()
Ecto.Adapters.SQL.Sandbox.mode(Skeleton.App.Repo, :manual)

ExUnit.start()
