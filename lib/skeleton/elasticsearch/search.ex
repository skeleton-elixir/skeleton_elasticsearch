defmodule Skeleton.Elasticsearch.Search do
  alias Skeleton.Elasticsearch.Config, as: Config

  defmacro __using__(opts) do
    alias Skeleton.Elasticsearch.{Search, Config}

    quote do
      @otp_app unquote(opts[:otp_app]) || raise("OTP App required")
      @elasticsearch unquote(opts[:elasticsearch]) || raise("Elasticsearch required")
      @index unquote(opts[:index]) || raise("Index required")
      @module __MODULE__

      def config, do: Config.get_module_config(@otp_app, @elasticsearch)

      def add_query(query, new_query), do: Search.add_query(query, new_query)

      def build_query(params, opts \\ []),
        do: Search.build_query(config(), @module, params, opts)

      def search(params, opts \\ []),
        do: Search.search(config(), @elasticsearch, @module, @index, params, opts)

      def search_from_query(query), do: @elasticsearch.search(@index, query)

      @before_compile Skeleton.Elasticsearch.Search
    end
  end

  defmacro __before_compile__(_) do
    quote do
      def start_query(_params), do: %{}
      def filter_by(query, _, _params), do: query
      def sort_by(query, _, _params), do: query
      def aggs_by(query, _, _params), do: query

      defoverridable start_query: 1, filter_by: 3, sort_by: 3, aggs_by: 3
    end
  end

  # All

  def search(config, elasticsearch, module, index, params, opts) do
    query = build_query(config, module, params, opts)
    elasticsearch.search(index, query, opts)
  end

  # Add query

  def add_query(query, new_query) do
    Map.merge(query, new_query, fn _k, v1, v2 ->
      cond do
        is_list(v2) -> v1 ++ v2
        is_map(v2) -> add_query(v1, v2)
        true -> v2
      end
    end)
  end

  # Build Query

  def build_query(config, module, params, opts) do
    params = stringfy_map(params)

    config
    |> Config.start_query()
    |> Map.merge(module.start_query(params))
    |> build_filters(module, params)
    |> build_sorts(config, module, params)
    |> build_size(opts)
    |> build_from(opts)
    |> build_aggs(config, module, params)
    |> build_function_score()
  end

  # Build filters

  defp build_filters(query, module, params) do
    Enum.reduce(params, query, fn {k, v}, search ->
      apply(module, :filter_by, [search, {to_string(k), v}, params])
    end)
  end

  # Build sorts

  defp build_sorts(query, config, module, params) do
    params
    |> Map.get(Config.sort_param(config), [])
    |> Enum.reduce(query, fn param, acc_query ->
      apply(module, :sort_by, [acc_query, to_string(param), params])
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

  defp build_aggs(query, config, module, params) do
    params
    |> Map.get(Config.aggs_param(config), [])
    |> Enum.reduce(query, fn param, acc_query ->
      apply(module, :aggs_by, [acc_query, to_string(param), params])
    end)
  end

  defp build_function_score(%{query: %{function_score: _}} = query) do
    {function_query, query} = pop_in(query, [:query, :function_score])
    {query, root_query} = pop_in(query, [:query])

    query =
      if query == %{} do
        %{}
      else
        %{query: query}
      end

    Map.merge(
      %{
        query: %{
          function_score: Map.merge(query, function_query)
        }
      },
      root_query
    )
  end

  defp build_function_score(query), do: query

  # stringfy map

  defp stringfy_map(map) do
    stringkeys = fn {k, v}, acc ->
      Map.put_new(acc, to_string(k), v)
    end

    Enum.reduce(map, %{}, stringkeys)
  end
end
