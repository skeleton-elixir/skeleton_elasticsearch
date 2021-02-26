defmodule Skeleton.Elasticsearch do
  alias Skeleton.Elasticsearch.Config

  defmacro __using__(_opts) do
    alias Skeleton.Elasticsearch

    quote do
      # Index
      def create_index(index, data), do: Elasticsearch.create_index(index, data)
      def update_index(index, data, params \\ []), do: Elasticsearch.update_index(index, data, params)
      def truncate_index(index), do: Elasticsearch.truncate_index(index)
      def drop_index(index), do: Elasticsearch.drop_index(index)

      # Document
      def create_document(index, id, data), do: Elasticsearch.create_document(index, id, data)

      def update_document(index, id, data),
        do: Elasticsearch.update_document(index, id, data)

      def update_documents_by_query(index, query, data, params \\ []),
        do: Elasticsearch.update_documents_by_query(index, query, data, params)

      def save_document(index, data), do: Elasticsearch.save_document(index, data)
      def save_document(index, id, data), do: Elasticsearch.save_document(index, id, data)
      def delete_document(index, id), do: Elasticsearch.delete_document(index, id)

      def delete_documents_by_query(index, query),
        do: Elasticsearch.delete_documents_by_query(index, query)

      # Search
      def search(index, query), do: Elasticsearch.search(index, query)

      # Refresh
      def refresh(index, opts \\ []), do: Elasticsearch.refresh(index, opts)

      # Schema migrations
      def create_schema_migrations_index(),
        do: Elasticsearch.create_schema_migrations_index()

      def migrate_schema_version(version),
        do: Elasticsearch.migrate_schema_version(version)
    end
  end

  # Create index

  def create_index(index, data) do
    url()
    |> Elastix.Index.create(add_prefix(index), data)
    |> parse_response(add_prefix(index))
  end

  # Update index

  def update_index(index, data, params) do
    url()
    |> Elastix.Mapping.put(add_prefix(index), nil, data, params)
    |> parse_response(add_prefix(index))
  end

  # Drop index

  def drop_index(index) do
    url()
    |> Elastix.Index.delete(add_prefix(index))
    |> parse_response(add_prefix(index))
  end

  # Truncate index

  def truncate_index(index) do
    index = "#{add_prefix(index)},-#{add_prefix("schema_migrations")}"
    query = %{query: %{match_all: %{}}}

    url()
    |> Elastix.Document.delete_matching(index, query)
    |> parse_response(index)
  end

  # Save document

  def save_document(index, data) do
    url()
    |> Elastix.Document.index_new(add_prefix(index), "_doc", data)
    |> parse_response(add_prefix(index))
  end

  def save_document(index, id, data) do
    url()
    |> Elastix.Document.index(add_prefix(index), "_doc", id, data)
    |> parse_response(add_prefix(index))
  end

  # Create document

  def create_document(index, data), do: save_document(index, data)

  def create_document(index, id, data), do: save_document(index, id, data)

  # Update document

  def update_document(index, id, data), do: save_document(index, id, data)

  # Update documents by query

  def update_documents_by_query(index, query, data, params \\ []) do
    url()
    |> Elastix.Document.update_by_query(add_prefix(index), query, data, params)
    |> parse_response(add_prefix(index))
  end

  # Delete document

  def delete_document(index, id) do
    url()
    |> Elastix.Document.delete(add_prefix(index), "_doc", id)
    |> parse_response(add_prefix(index))
  end

  # Delete documents by query

  def delete_documents_by_query(index, query) do
    url()
    |> Elastix.Document.delete_matching(add_prefix(index), query)
    |> parse_response(add_prefix(index))
  end

  # Search

  def search(index, query) do
    url()
    |> Elastix.Search.search(add_prefix(index), [], query)
    |> parse_response(add_prefix(index))
    |> case do
      {:ok, body} -> body
      {:error, error} -> raise(RuntimeError, error)
    end
  end

  # Refresh

  def refresh(index, opts \\ []) do
    if refresh?() || opts[:force], do: Elastix.Index.refresh(url(), index)
  end

  # Parse response

  defp parse_response(response, index) do
    refresh(index)

    case response do
      {:ok, %{body: %{"error" => error}}} ->
        {:error, error["reason"]}

      {:ok, response} ->
        {:ok, response.body}

      {:error, error} ->
        {:error, error}
    end
  end

  # Create schema migrations index

  def create_schema_migrations_index() do
    query = %{
      settings: %{
        index: %{
          number_of_shards: 1,
          number_of_replicas: 0
        }
      },
      mappings: %{
        dynamic: false,
        properties: %{
          version: %{type: "long"}
        }
      }
    }

    create_index("schema_migrations", query)
  end

  # Migrate to new version

  def migrate_schema_version(version) do
    data = %{version: version}
    save_document("schema_migrations", data)
  end

  # Url

  defp url(), do: Config.url()

  defp refresh?(), do: Config.refresh()

  defp add_prefix(index), do: "#{Config.prefix()}-#{index}"
end
