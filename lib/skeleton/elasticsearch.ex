defmodule Skeleton.Elasticsearch do
  alias Skeleton.Elasticsearch.Config
  import Ecto.Query

  defmacro __using__(opts) do
    alias Skeleton.Elasticsearch
    alias Skeleton.Elasticsearch.Config

    quote do
      @otp_app unquote(opts[:otp_app]) || raise("OTP App required")
      @module __MODULE__

      def config, do: Config.get_module_config(@otp_app, @module)

      # Index
      def index_name(index, opts \\ []),
        do: Elasticsearch.index_name(config(), index, opts)

      def get_index(index, opts \\ []),
        do: Elasticsearch.get_index(config(), index, opts)

      def create_index(index, data, opts \\ []),
        do: Elasticsearch.create_index(config(), index, data, opts)

      def update_index(index, data, params \\ [], opts \\ []),
        do: Elasticsearch.update_index(config(), index, data, params, opts)

      def truncate_index(index, url_params \\ [], opts \\ []),
        do: Elasticsearch.truncate_index(config(), index, url_params, opts)

      def drop_index(index, opts \\ []),
        do: Elasticsearch.drop_index(config(), index, opts)

      # Document
      def create_document(index, id, data, url_params \\ [], opts \\ []),
        do: Elasticsearch.create_document(config(), index, id, data, url_params, opts)

      def update_document(index, id, data, url_params \\ [], opts \\ []),
        do: Elasticsearch.update_document(config(), index, id, data, url_params, opts)

      def update_document_by_script(index, id, data, url_params \\ [], opts \\ []),
        do: Elasticsearch.update_document_by_script(config(), index, id, data, url_params, opts)

      def update_documents_by_query(index, query, script, url_params \\ [], opts \\ []) do
        Elasticsearch.update_documents_by_query(config(), index, query, script, url_params, opts)
      end

      def save_document(index, id, data, url_params \\ [], opts \\ []),
        do: Elasticsearch.save_document(config(), index, id, data, url_params, opts)

      def delete_document(index, id, url_params \\ [], opts \\ []),
        do: Elasticsearch.delete_document(config(), index, id, url_params, opts)

      def delete_documents_by_query(index, query, url_params \\ [], opts \\ []),
        do: Elasticsearch.delete_documents_by_query(config(), index, query, url_params, opts)

      def delete_outdated_documents(index, synced_at, url_params \\ [], opts \\ []),
        do: Elasticsearch.delete_outdated_documents(config(), index, synced_at, url_params, opts)

      def bulk(index, rows, url_params \\ [], opts \\ []),
        do: Elasticsearch.bulk(config(), index, rows, url_params, opts)

      def sync(index, query, preload, id_field, data, url_params \\ [], opts \\ []) do
        Elasticsearch.sync(config(), index, query, preload, id_field, data, url_params, opts)
      end

      # Search
      def search(index, query, opts \\ []), do: Elasticsearch.search(config(), index, query, opts)

      # Count
      def count(index, query, opts \\ []), do: Elasticsearch.count(config(), index, query, opts)

      # Refresh
      def refresh(index, opts \\ []) do
        index = Elasticsearch.index_name(config(), index, opts)
        Elasticsearch.refresh(config(), index, opts)
      end

      # Schema migrations
      def create_schema_migrations_index(opts \\ []),
        do: Elasticsearch.create_schema_migrations_index(config(), opts)

      def migrate_schema_version(version, opts \\ []),
        do: Elasticsearch.migrate_schema_version(config(), version, opts)

      def prefixes, do: []

      defoverridable prefixes: 0
    end
  end

  # Get Index

  def get_index(config, index, opts) do
    index = index_name(config, index, opts)

    url(config)
    |> Elastix.Index.get(index)
    |> parse_response(config, index)
  end

  # Create index

  def create_index(config, index, data, opts) do
    index = index_name(config, index, opts)

    data_with_last_synced_at =
      put_in(data, [:mappings, :properties, last_synced_at_field(config)], %{
        type: :date
      })

    url(config)
    |> Elastix.Index.create(index, data_with_last_synced_at)
    |> parse_response(config, index)
  end

  # Update index

  def update_index(config, index, data, url_params, opts) do
    index = index_name(config, index, opts)

    url(config)
    |> Elastix.Mapping.put(index, "", data, url_params)
    |> parse_response(config, index)
  end

  # Drop index

  def drop_index(config, index, opts) do
    index = index_name(config, index, opts)

    url(config)
    |> Elastix.Index.delete(index)
    |> parse_response(config, index)
  end

  # Truncate index

  def truncate_index(config, index, url_params, opts) do
    index = index_name(config, index, opts)

    index = "#{index},-#{index_name(config, "*schema_migrations*", opts)}"
    query = %{query: %{match_all: %{}}}

    url(config)
    |> Elastix.Document.delete_matching(index, query, url_params)
    |> parse_response(config, index)
  end

  # Save document

  def save_document(config, index, nil, data, url_params, opts) do
    index = index_name(config, index, opts)

    url(config)
    |> Elastix.Document.index_new(index, "_doc", data, url_params)
    |> parse_response(config, index)
  end

  def save_document(config, index, id, data, url_params, opts) do
    index = index_name(config, index, opts)

    url(config)
    |> Elastix.Document.index(index, "_doc", id, data, url_params)
    |> parse_response(config, index)
  end

  # Create document

  def create_document(config, index, id, data, url_params, opts),
    do: save_document(config, index, id, data, url_params, opts)

  # Update document

  def update_document(config, index, id, data, url_params, opts) do
    index = index_name(config, index, opts)

    url(config)
    |> Elastix.Document.update(index, "_doc", id, %{doc: data}, url_params)
    |> parse_response(config, index)
  end

  # Update document by script

  def update_document_by_script(config, index, id, script, url_params, opts) do
    index = index_name(config, index, opts)

    url(config)
    |> Elastix.Document.update(index, "_doc", id, %{script: script}, url_params)
    |> parse_response(config, index)
  end

  # Update documents by query

  def update_documents_by_query(config, index, query, script, url_params, opts) do
    index = index_name(config, index, opts)

    url(config)
    |> Elastix.Document.update_by_query(index, query, script, url_params)
    |> parse_response(config, index)
  end

  # Delete document

  def delete_document(config, index, id, url_params, opts) do
    index = index_name(config, index, opts)

    url(config)
    |> Elastix.Document.delete(index, "_doc", id, url_params)
    |> parse_response(config, index)
  end

  # Delete documents by query

  def delete_documents_by_query(config, index, query, url_params, opts) do
    index = index_name(config, index, opts)

    url(config)
    |> Elastix.Document.delete_matching(index, %{query: query}, url_params)
    |> parse_response(config, index)
  end

  # Bulk

  def bulk(config, index, rows, url_params, opts) do
    index = index_name(config, index, opts)

    url(config)
    |> Elastix.Bulk.post(
      rows,
      [
        index: index,
        type: "_doc"
      ] ++ (opts[:bulk_opts] || []),
      url_params
    )
    |> parse_response(config, index)
  end

  # Sync

  def sync(config, index, query, preload, id_field, func_prepare_item, url_params, opts) do
    synced_at = DateTime.utc_now()
    repo = opts[:repo] || repo(config)
    size = opts[:size] || sync_size(config)
    sync_interval = opts[:sync_interval] || sync_interval(config)
    delete_outdated = Keyword.get(opts, :delete_outdated, true)

    do_sync(%{
      query: query,
      repo: repo,
      size: size,
      offset: 0,
      sync_interval: sync_interval,
      synced_at: synced_at,
      config: config,
      index: index,
      preload: preload,
      id_field: id_field,
      func_prepare_item: func_prepare_item,
      url_params: url_params,
      opts: opts
    })

    if delete_outdated do
      delete_outdated_documents(config, index, synced_at, [], [])
    end

    :ok
  end

  defp do_sync(opts) do
    query = from(opts[:query], limit: ^opts[:size], offset: ^opts[:offset])

    result =
      query
      |> opts[:repo].all(opts[:opts])
      |> opts[:repo].preload(opts[:preload])

    if length(result) > 0 do
      rows =
        Enum.map(result, fn item ->
          [
            %{index: %{_id: Map.get(item, opts[:id_field])}},
            Map.put(
              opts[:func_prepare_item].(item),
              last_synced_at_field(opts[:config]),
              opts[:synced_at]
            )
          ]
        end)

      {:ok, _} =
        bulk(opts[:config], opts[:index], List.flatten(rows), opts[:url_params], opts[:opts])

      if opts[:sync_interval] > 0, do: :timer.sleep(opts[:sync_interval])

      do_sync(%{opts | offset: opts[:offset] + opts[:size]})
    else
      nil
    end
  end

  # Delete outdated docs

  def delete_outdated_documents(config, index, synced_at, url_params, opts) do
    delete_query = %{
      range: %{
        last_synced_at_field(config) => %{
          lt: synced_at
        }
      }
    }

    delete_documents_by_query(config, index, delete_query, url_params, opts)
  end

  # Search

  def search(config, index, query, opts) do
    index = index_name(config, index, opts)

    url(config)
    |> Elastix.Search.search(index, [], query)
    |> parse_response(config, index)
    |> case do
      {:ok, body} -> body
      {:error, error} -> raise(RuntimeError, error)
    end
  end

  # Count

  def count(config, index, query, opts) do
    index = index_name(config, index, opts)

    url(config)
    |> Elastix.Search.count(index, [], query)
    |> parse_response(config, index)
    |> case do
      {:ok, body} -> body
      {:error, error} -> raise(RuntimeError, error)
    end
  end

  # Refresh

  def refresh(config, index, opts \\ []) do
    if refresh?(config) || opts[:force], do: Elastix.Index.refresh(url(config), index)
  end

  # Parse response

  defp parse_response(response, config, index) do
    refresh(config, index)

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

  def create_schema_migrations_index(config, opts) do
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

    create_index(config, "schema_migrations", query, opts)
  end

  # Migrate to new version

  def migrate_schema_version(config, version, opts) do
    data = %{version: version}
    save_document(config, "schema_migrations", nil, data, [], opts)
  end

  # Url

  defp url(config), do: Config.url(config)

  defp refresh?(config), do: Config.refresh(config)

  defp repo(config), do: Config.repo(config)

  defp last_synced_at_field(config), do: String.to_atom(Config.last_synced_at_field(config))

  defp sync_interval(config), do: Config.sync_interval(config)

  defp sync_size(config), do: Config.sync_size(config)

  def index_name(config, index, opts \\ []) do
    [
      opts[:namespace] || Config.namespace(config),
      opts[:prefix] || Config.prefix(config),
      index,
      opts[:suffix] || Config.suffix(config)
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.join("-")
  end
end
