defmodule Skeleton.App.UserIndex do
  import Skeleton.App.Elasticsearch

  @index "users"

  # Build user

  def build(:user, user) do
    %{
      name: user.name,
      email: user.email,
      inserted_at: user.inserted_at,
      updated_at: user.updated_at,
      last_synced_at: DateTime.utc_now()
    }
  end

  # Save user

  def create(:user, user) do
    save_document(@index, user.id, build(:user, user))
  end

  # Update user

  def update(:user, user) do
    update_document(@index, user.id, build(:user, user))
  end

  # Delete user

  def delete(:user, user) do
    delete_document(@index, user.id)
  end

  # Sync

  def sync(query \\ User) do
    sync(@index, query, [:pets_with_deleted, :state, :city], :id, fn user ->
      user_data = build(:user, user)

      pets_data = %{
        total_pets: length(user.pets_with_deleted),
        total_adopted_pets: Enum.count(user.pets_with_deleted, &(not is_nil(&1.adopted_at))),
        total_avaiable_pets: Enum.count(user.pets_with_deleted, &is_nil(&1.adopted_at))
      }

      Map.merge(user_data, pets_data)
    end)
  end
end
