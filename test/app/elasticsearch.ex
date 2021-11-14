defmodule Skeleton.App.Elasticsearch do
  @moduledoc false

  use Skeleton.Elasticsearch, otp_app: :skeleton_elasticsearch

  def prefixes do
    ["tenant1"]
  end
end
