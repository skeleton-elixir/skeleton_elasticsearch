defmodule Skeleton.App.Repo do
  use Ecto.Repo, otp_app: :skeleton_elasticsearch, adapter: Ecto.Adapters.Postgres
end
