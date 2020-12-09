defmodule Skeleton.Elasticsearch do
  alias Skeleton.Elasticsearch.Config

  defmacro __using__(_opts) do
    alias Skeleton.Elasticsearch

    quote do
      def create_index(index, query), do: Elasticsearch.create_index(index, query)
      def save_document(index, id, data), do: Elasticsearch.save_document(index, id, data)
      def delete_document(index, id), do: Elasticsearch.delete_document(index, id)
      def delete_documents(index, query), do: Elasticsearch.delete_documents(index, query)
      def delete_all(index), do: Elasticsearch.delete_all(index)
      def drop(index), do: Elasticsearch.drop(index)
      def search(index, query), do: Elasticsearch.search(index, query)
    end
  end

  # Create index

  def create_index(index, query) do
    result = Elastix.Index.create(url(), add_prefix(index), query)
    refresh(index)
    result
  end

  # Save document

  def save_document(index, id, data) do
    result = Elastix.Document.index(url(), add_prefix(index), "_doc", id, data)
    refresh(index)
    result
  end

  # Delete document

  def delete_document(index, id) do
    result = Elastix.Document.delete(url(), add_prefix(index), "_doc", id)
    refresh(index)
    result
  end

  # Delete documents

  def delete_documents(index, query) do
    result = Elastix.Document.delete_matching(url(), add_prefix(index), query)
    refresh(index)
    result
  end

  # Delete all

  def delete_all(index) do
    query = %{query: %{match_all: %{}}}
    result = Elastix.Document.delete_matching(url(), add_prefix(index), query)
    refresh(index)
    result
  end

  # Drop index

  def drop(index) do
    Elastix.Document.delete(url(), add_prefix(index), "", "")
    refresh(index)
  end

  # Search

  def search(index, query) do
    case Elastix.Search.search(url(), add_prefix(index), [], query) do
      {:ok, %{body: %{"error" => error}}} ->
        raise(RuntimeError, error)

      {:ok, result} ->
        result.body

      {:error, error} ->
        raise(RuntimeError, error.reason)
    end
  end

  # Refresh

  def refresh(index) do
    if refresh?(), do: Elastix.Index.refresh(url(), add_prefix(index))
  end

  # Url

  defp url(), do: Config.url()

  defp refresh?(), do: Config.refresh()

  defp add_prefix(index), do: "#{Config.prefix()}-#{index}"
end
