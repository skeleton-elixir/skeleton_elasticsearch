# Sobre o Skeleton Elasticsearch

O Skeleton Elasticsearch ajuda a criar composes para queries feitas usando o Elastix.

## Instalação e configuração

```elixir
# mix.exs

def deps do
  [
    {:skeleton_elasticsearch, "~> 1.2.7"}
  ]
end
```

```elixir
# config/config.exs

config :elastix,
  httpoison_options: [timeout: 300_000, recv_timeout: 300_000]

config :app, elasticsearch_modules: [App.Elasticsearch]

config :app, App.Elasticsearch,
  repo: App.Repo,
  url: "http://localhost:9200",
  namespace: :app
```

```elixir
# config/dev.exs

config :app, App.Elasticsearch, suffix: :dev
```

```elixir
# config/test.exs

config :app, App.Elasticsearch, refresh: true, suffix: :test
```

```elixir
# lib/app/elasticsearch.ex

defmodule App.Elasticsearch do
  use Skeleton.Elasticsearch, otp_app: :app
end
```

```elixir
# lib/app/search.ex

defmodule App.Search do
  defmacro __using__(opts) do
    quote do
      use Skeleton.Elasticsearch.Search,
        otp_app: :app,
        elasticsearch: unquote(opts[:elasticsearch]) || App.Elasticsearch,
        index: unquote(opts[:index])
    end
  end
end
```

## Criando o serviço de indexação

```elixir
# lib/app/accounts/user/user_index.ex

defmodule App.UserIndex do
  import App.Elasticsearch
  import Ecto.Query
  alias App.Repo

  @index "users"
  @preload [:groups]

  # Build user

  def build(user) do
    user = Repo.preload(user, @preload)

    %{
      name: user.name,
      email: user.email,
      inserted_at: user.inserted_at,
      updated_at: user.updated_at
    }
  end

  # Save user

  def create(user) do
    save_document(@index, user.id, build(user))
  end

  # Update user

  def update(:user, user) do
    update_document(@index, user.id, build(user))
  end

  # Delete user

  def delete(:user, user) do
    delete_document(@index, user.id)
  end

  # Sync

  def sync(query \\ User) do
    query =
      from(u in query,
        order_by: [u.updated_at, u.id]
      )

    sync(@index, query, @preload, :id, &build/1)
  end
end
```

## Criando o serviço de busca

```elixir
# lib/app/accounts/user/user_search.ex

defmodule App.UserSearch do
  use App.Search, index: "users"

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
```

## Exemplo de chamada do serviço

```elixir
App.Accounts.UserIndex.create(user)
App.Accounts.UserIndex.update(user)
App.Accounts.UserIndex.delete(user)
App.Accounts.UserIndex.sync() # Deleting outdated docs
App.Accounts.UserIndex.sync(delete_outdated: false) # Deleting outdated docs

App.Accounts.UserSearch.search(%{
  id: user.id,
  sort_by: ["inserted_at_desc"]
})
```