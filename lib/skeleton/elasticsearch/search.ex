defmodule Skeleton.Elasticsearch.Search do
  @moduledoc """
  The Skeleton Search module
  """

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

      def start_query(_params), do: %{}

      def end_query(query, _params), do: query

      @before_compile Skeleton.Elasticsearch.Search

      defoverridable start_query: 1, end_query: 2
    end
  end

  defmacro __before_compile__(_) do
    quote do
      def compose(query, _, _params), do: query

      defoverridable compose: 3
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
    params =
      params
      |> stringfy_map()
      |> allow_params(opts[:allow])
      |> deny_params(opts[:deny])
      |> allow_sort_by_params(opts[:allow], config)
      |> deny_sort_by_params(opts[:deny], config)
      |> allow_aggs_by_params(opts[:allow], config)
      |> deny_aggs_by_params(opts[:deny], config)

    config
    |> Config.start_query()
    |> Map.merge(module.start_query(params))
    |> build_composers(module, params)
    |> build_sort_by_composers(config, module, params)
    |> build_size(opts)
    |> build_from(opts)
    |> build_aggs_by_composers(config, module, params)
    |> build_function_score()
    |> build_end_query(module, params)
  end

  # Build filters

  defp build_composers(query, module, params) do
    Enum.reduce(params, query, fn {k, v}, search ->
      apply(module, :compose, [search, {to_string(k), v}, params])
    end)
  end

  # Build sorts

  defp build_sort_by_composers(query, config, module, params) do
    params
    |> Map.get(Config.sort_param(config), [])
    |> Enum.reduce(query, fn o, acc_query ->
      apply(module, :compose, [acc_query, {Config.sort_param(config), to_string(o)}, params])
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

  defp build_aggs_by_composers(query, config, module, params) do
    params
    |> Map.get(Config.aggs_param(config), [])
    |> Enum.reduce(query, fn o, acc_query ->
      apply(module, :compose, [acc_query, {Config.aggs_param(config), to_string(o)}, params])
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

  # End query

  defp build_end_query(query, module, params) do
    module.end_query(query, params)
  end

  # stringfy map

  defp stringfy_map(map) do
    stringkeys = fn {k, v}, acc ->
      Map.put_new(acc, to_string(k), v)
    end

    Enum.reduce(map, %{}, stringkeys)
  end

  # Allow sort by params

  defp allow_sort_by_params(params, nil, _config), do: params

  defp allow_sort_by_params(params, allow, config) do
    allow_list_params(params, allow, Config.sort_param(config))
  end

  # Deny sort by params

  defp deny_sort_by_params(params, nil, _config), do: params

  defp deny_sort_by_params(params, deny, config) do
    deny_list_params(params, deny, Config.sort_param(config))
  end

  # Allow aggs by params

  defp allow_aggs_by_params(params, nil, _config), do: params

  defp allow_aggs_by_params(params, allow, config) do
    allow_list_params(params, allow, Config.aggs_param(config))
  end

  # Deny aggs by params

  defp deny_aggs_by_params(params, nil, _config), do: params

  defp deny_aggs_by_params(params, deny, config) do
    deny_list_params(params, deny, Config.aggs_param(config))
  end

  # Allow list params

  defp allow_list_params(params, allow, config_param) do
    allow
    |> Keyword.get(String.to_atom(config_param))
    |> case do
      p when is_list(p) ->
        allow = Enum.map(p, &to_string/1)
        sort_params = params[config_param] || []
        allowed_sort = sort_params -- sort_params -- allow
        Map.put(params, config_param, allowed_sort)

      _ ->
        params
    end
  end

  # Deny list params

  defp deny_list_params(params, deny, config_param) do
    deny
    |> Keyword.get(String.to_atom(config_param))
    |> case do
      p when is_list(p) ->
        deny = Enum.map(p, &to_string/1)
        sort_params = params[config_param] || []
        allowed_sort = sort_params -- deny
        Map.put(params, config_param, allowed_sort)

      _ ->
        params
    end
  end

  # Allow params

  defp allow_params(params, nil), do: params

  defp allow_params(params, allow) do
    allow =
      Enum.map(allow, fn a ->
        case a do
          a when is_atom(a) -> to_string(a)
          a when is_binary(a) -> a
          {k, _} -> to_string(k)
          _ -> ""
        end
      end)

    Map.take(params, allow)
  end

  # deny params

  defp deny_params(params, nil), do: params

  defp deny_params(params, deny) do
    deny =
      Enum.map(deny, fn a ->
        case a do
          a when is_atom(a) -> to_string(a)
          a when is_binary(a) -> a
          _ -> ""
        end
      end)

    Map.drop(params, deny)
  end
end
