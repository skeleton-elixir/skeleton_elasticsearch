defmodule Skeleton.App.User do
  use Skeleton.App, :schema

  schema "users" do
    field :name, :string
    field :email, :string
    field :admin, :boolean

    timestamps()
  end
end
