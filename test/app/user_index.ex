defmodule Skeleton.App.UserIndex do
  import Skeleton.App.Elasticsearch

  @index "users"

  # Build user

  def build(user) do
    %{
      name: user.name,
      email: user.email,
      inserted_at: user.inserted_at,
      updated_at: user.updated_at,
      last_synced_at: DateTime.utc_now()
    }
  end

  # Save user

  def create(user) do
    save_document(@index, user.id, build(user))
  end

  # Update user

  def update(:user, user) do
    update_document(@index, user.id, build(user))
  end

  # Delete user

  def delete(:user, user) do
    delete_document(@index, user.id)
  end

  # Sync

  def sync(query \\ User) do
    sync(@index, query, [], :id, &build/1)
  end
end
