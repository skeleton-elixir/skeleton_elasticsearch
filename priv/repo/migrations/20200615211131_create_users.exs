defmodule Skeleton.App.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:name, :string)
      add(:email, :string)
      add(:admin, :boolean, default: false)

      timestamps()
    end
  end
end
