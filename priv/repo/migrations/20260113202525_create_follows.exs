defmodule AinComBooking.Repo.Migrations.CreateFollows do
  @moduledoc false
  use Ecto.Migration

  def change do
    create table(:follows, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:follower_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false)
      add(:followed_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(unique_index(:follows, [:follower_id, :followed_id]))
    create(index(:follows, [:followed_id]))
  end
end
