defmodule Skeleton.Elasticsearch.Search do
  alias Skeleton.Elasticsearch.Config, as: Config

  # Callbacks

  defmacro __using__(opts) do
    alias Skeleton.Elasticsearch.{Search, Config}

    quote do
      @elasticsearch unquote(opts[:elasticsearch]) || Config.elasticsearch() || raise("Elasticsearch module required")
      @index unquote(opts[:index]) || raise("Index required")

      def add_query(query, new_query), do: Search.add_query(query, new_query)
      def search(params, opts \\ []), do: Search.search(__MODULE__, @elasticsearch, @index, params, opts)

      @before_compile Skeleton.Elasticsearch.Search
    end
  end

  defmacro __before_compile__(_) do
    quote do
      def filter_by(search, _, _args), do: search
      def sort_by(search, _, _args), do: search

      defoverridable filter_by: 3, sort_by: 3
    end
  end

  # All

  def search(module, elasticsearch, index, params, _opts) do
    query = prepare_search(module, params)
    elasticsearch.search(index, query)
  end

  # Add query

  def add_query(query, new_query) do
    Map.merge(query, new_query, fn k, v1, v2 ->
      cond do
        is_list(v2) -> v1 ++ v2
        is_map(v2) -> add_query(v1, v2)
        true -> Map.put(v1, k, v2)
      end
    end)
  end

  # Prepare search

  defp prepare_search(module, params) do
    params
    |> build_filters(module)
    |> build_sorts(module, params)
  end

  # Build filters

  defp build_filters(params, module) do
    Enum.reduce(params, %{}, fn f, search ->
      apply(module, :filter_by, [search, f, params])
    end)
  end

  # Build sorts

  defp build_sorts(query, module, params) do
    params
    |> Map.get(Config.sort_param(), [])
    |> Enum.map(&String.to_atom/1)
    |> Enum.reduce(query, fn o, search ->
      apply(module, :sort_by, [search, o, params])
    end)
  end
end
