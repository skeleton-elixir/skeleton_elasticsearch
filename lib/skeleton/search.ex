defmodule Skeleton.Elasticsearch.Search do
  alias Skeleton.Elasticsearch.Config, as: Config

  # Callbacks

  defmacro __using__(opts) do
    alias Skeleton.Elasticsearch.{Search, Config}

    quote do
      @elasticsearch unquote(opts[:elasticsearch]) || Config.elasticsearch() ||
                       raise("Elasticsearch module required")
      @index unquote(opts[:index]) || raise("Index required")

      def add_query(query, new_query), do: Search.add_query(query, new_query)

      def build_query(params, opts \\ []),
        do: Search.build_query(__MODULE__, params, opts)

      def search(params, opts \\ []),
        do: Search.search(__MODULE__, @elasticsearch, @index, params, opts)

      def search_from_query(query), do: @elasticsearch.search(@index, query)

      @before_compile Skeleton.Elasticsearch.Search
    end
  end

  defmacro __before_compile__(_) do
    quote do
      def filter_by(query, _, _args), do: query
      def sort_by(query, _, _args), do: query
      def aggs_by(query, _, _args), do: query

      defoverridable filter_by: 3, sort_by: 3, aggs_by: 3
    end
  end

  # All

  def search(module, elasticsearch, index, params, opts) do
    query = build_query(module, params, opts)
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

  # Build Query

  def build_query(module, params, opts) do
    params
    |> build_filters(module)
    |> build_sorts(module, params)
    |> build_size(opts)
    |> build_from(opts)
    |> build_aggs(module, params)
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
    |> Enum.map(&String.to_atom(to_string(&1)))
    |> Enum.reduce(query, fn o, acc_query ->
      apply(module, :sort_by, [acc_query, o, params])
    end)
  end

  # Build size

  defp build_size(query, opts) do
    if size = opts[:size] do
      add_query(query, %{size: size})
    else
      query
    end
  end

  # Build from

  defp build_from(query, opts) do
    if from = opts[:from] do
      add_query(query, %{from: from})
    else
      query
    end
  end

  # Build aggs

  defp build_aggs(query, module, params) do
    Enum.reduce(params, query, fn o, acc_query ->
      apply(module, :aggs_by, [acc_query, o, params])
    end)
  end
end
