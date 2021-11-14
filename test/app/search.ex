defmodule Skeleton.App.Search do
  @moduledoc false

  defmacro __using__(opts) do
    quote do
      use Skeleton.Elasticsearch.Search,
        otp_app: :skeleton_elasticsearch,
        elasticsearch: unquote(opts[:elasticsearch]) || Skeleton.App.Elasticsearch,
        index: unquote(opts[:index])
    end
  end
end
