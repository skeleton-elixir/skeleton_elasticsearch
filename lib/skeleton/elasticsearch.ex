defmodule Skeleton.Elasticsearch do
  alias Skeleton.Elasticsearch.Config

  defmacro __using__(_opts) do
    alias Skeleton.Elasticsearch

    quote do
      # Index
      def index_name(index, opts \\ []), do: Elasticsearch.index_name(index, opts)

      def get_index(index, opts \\ []), do: Elasticsearch.get_index(index, opts)

      def create_index(index, data, opts \\ []), do: Elasticsearch.create_index(index, data, opts)

      def update_index(index, data, params \\ [], opts \\ []),
        do: Elasticsearch.update_index(index, data, params, opts)

      def truncate_index(index, url_params \\ [], opts \\ []),
        do: Elasticsearch.truncate_index(index, url_params, opts)

      def drop_index(index, opts \\ []), do: Elasticsearch.drop_index(index, opts)

      # Document
      def create_document(index, id, data, url_params \\ [], opts \\ []),
        do: Elasticsearch.create_document(index, id, data, url_params, opts)

      def update_document(index, id, data, url_params \\ [], opts \\ []),
        do: Elasticsearch.update_document(index, id, data, url_params, opts)

      def update_document_by_script(index, id, data, url_params \\ [], opts \\ []),
        do: Elasticsearch.update_document_by_script(index, id, data, url_params, opts)

      def update_documents_by_query(index, query, script, url_params \\ [], opts \\ []),
        do: Elasticsearch.update_documents_by_query(index, query, script, url_params, opts)

      def save_document(index, id, data, url_params \\ [], opts \\ []),
        do: Elasticsearch.save_document(index, id, data, url_params, opts)

      def delete_document(index, id, url_params \\ [], opts \\ []),
        do: Elasticsearch.delete_document(index, id, url_params, opts)

      def delete_documents_by_query(index, query, url_params \\ [], opts \\ []),
        do: Elasticsearch.delete_documents_by_query(index, query, url_params, opts)

      def bulk(index, rows, url_params \\ [], opts \\ []),
        do: Elasticsearch.bulk(index, rows, url_params, opts)

      def sync(
            index,
            query,
            preload,
            id_field,
            data,
            url_params \\ [],
            opts \\ []
          ),
          do: Elasticsearch.sync(index, query, preload, id_field, data, url_params, opts)

      # Search
      def search(index, query, opts \\ []), do: Elasticsearch.search(index, query, opts)

      # Refresh
      def refresh(index, opts \\ []),
        do: index |> Elasticsearch.index_name(opts) |> Elasticsearch.refresh(opts)

      # Schema migrations
      def create_schema_migrations_index(opts \\ []),
        do: Elasticsearch.create_schema_migrations_index(opts)

      def migrate_schema_version(version, opts \\ []),
        do: Elasticsearch.migrate_schema_version(version, opts)

      def migrate(opts \\ []), do: Skeleton.Elasticsearch.Migrate.run(opts)

      def prefixes, do: []

      defoverridable prefixes: 0
    end
  end

  # Get Index

  def get_index(index, opts) do
    index = index_name(index, opts)

    url()
    |> Elastix.Index.get(index)
    |> parse_response(index)
  end

  # Create index

  def create_index(index, data, opts) do
    index = index_name(index, opts)

    data_with_last_synced_at =
      put_in(data, [:mappings, :properties, last_synced_at_field()], %{
        type: :date
      })

    url()
    |> Elastix.Index.create(index, data_with_last_synced_at)
    |> parse_response(index)
  end

  # Update index

  def update_index(index, data, url_params, opts) do
    index = index_name(index, opts)

    url()
    |> Elastix.Mapping.put(index, "", data, url_params)
    |> parse_response(index)
  end

  # Drop index

  def drop_index(index, opts) do
    index = index_name(index, opts)

    url()
    |> Elastix.Index.delete(index)
    |> parse_response(index)
  end

  # Truncate index

  def truncate_index(index, url_params, opts) do
    index = index_name(index, opts)

    index = "#{index},-#{index_name("*schema_migrations*", opts)}"
    query = %{query: %{match_all: %{}}}

    url()
    |> Elastix.Document.delete_matching(index, query, url_params)
    |> parse_response(index)
  end

  # Save document

  def save_document(index, nil, data, url_params, opts) do
    index = index_name(index, opts)

    url()
    |> Elastix.Document.index_new(index, "_doc", data, url_params)
    |> parse_response(index)
  end

  def save_document(index, id, data, url_params, opts) do
    index = index_name(index, opts)

    url()
    |> Elastix.Document.index(index, "_doc", id, data, url_params)
    |> parse_response(index)
  end

  # Create document

  def create_document(index, id, data, url_params, opts),
    do: save_document(index, id, data, url_params, opts)

  # Update document

  def update_document(index, id, data, url_params, opts) do
    index = index_name(index, opts)

    url()
    |> Elastix.Document.update(index, "_doc", id, %{doc: data}, url_params)
    |> parse_response(index)
  end

  # Update document by script

  def update_document_by_script(index, id, script, url_params, opts) do
    index = index_name(index, opts)

    url()
    |> Elastix.Document.update(index, "_doc", id, %{script: script}, url_params)
    |> parse_response(index)
  end

  # Update documents by query

  def update_documents_by_query(index, query, script, url_params, opts) do
    index = index_name(index, opts)

    url()
    |> Elastix.Document.update_by_query(index, query, script, url_params)
    |> parse_response(index)
  end

  # Delete document

  def delete_document(index, id, url_params, opts) do
    index = index_name(index, opts)

    url()
    |> Elastix.Document.delete(index, "_doc", id, url_params)
    |> parse_response(index)
  end

  # Delete documents by query

  def delete_documents_by_query(index, query, url_params, opts) do
    index = index_name(index, opts)

    url()
    |> Elastix.Document.delete_matching(index, %{query: query}, url_params)
    |> parse_response(index)
  end

  # Bulk

  def bulk(index, rows, url_params, opts) do
    index = index_name(index, opts)

    url()
    |> Elastix.Bulk.post(
      rows,
      [
        index: index,
        type: "_doc"
      ] ++ (opts[:bulk_opts] || []),
      url_params
    )
    |> parse_response(index)
  end

  # Sync

  def sync(index, query, preload, id_field, func_prepare_item, url_params, opts) do
    synced_at = DateTime.utc_now()
    repo = opts[:repo] || repo()
    size = opts[:size] || 500

    IO.inspect "====================="
    IO.inspect(opts)
    IO.inspect "====================="

    repo.transaction(fn ->
      query
      |> repo.stream(opts)
      |> stream_preload(repo, size, preload)
      |> Stream.map(fn item ->
        [
          %{index: %{_id: Map.get(item, id_field)}},
          Map.put(func_prepare_item.(item), last_synced_at_field(), synced_at)
        ]
      end)
      |> Stream.chunk_every(size)
      |> Stream.each(fn rows ->
        bulk(index, List.flatten(rows), url_params, opts)
      end)
      |> Enum.to_list()
    end)

    delete_query = %{
      range: %{
        last_synced_at_field() => %{
          lt: synced_at
        }
      }
    }

    delete_documents_by_query(index, delete_query, [], [])
  end

  # Search

  def search(index, query, opts) do
    index = index_name(index, opts)

    url()
    |> Elastix.Search.search(index, [], query)
    |> parse_response(index)
    |> case do
      {:ok, body} -> body
      {:error, error} -> raise(RuntimeError, error)
    end
  end

  # Refresh

  def refresh(index, opts \\ []) do
    if refresh?() || opts[:force], do: Elastix.Index.refresh(url(), index)
  end

  # Repo stream preload

  defp stream_preload(stream, repo, size, preloads) do
    stream
    |> Stream.chunk_every(size)
    |> Stream.flat_map(&repo.preload(&1, preloads))
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

  def create_schema_migrations_index(opts) do
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

    create_index("schema_migrations", query, opts)
  end

  # Migrate to new version

  def migrate_schema_version(version, opts) do
    data = %{version: version}
    save_document("schema_migrations", nil, data, [], opts)
  end

  # Url

  defp url(), do: Config.url()

  defp refresh?(), do: Config.refresh()

  defp repo(), do: Config.repo()

  defp last_synced_at_field(), do: String.to_atom(Config.last_synced_at_field())

  def index_name(index, opts \\ []) do
    [
      opts[:namespace] || Config.namespace(),
      opts[:prefix] || Config.prefix(),
      index,
      opts[:suffix] || Config.suffix()
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.join("-")
  end
end
