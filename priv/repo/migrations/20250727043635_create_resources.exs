defmodule AinComBooking.Repo.Migrations.CreateResources do
  @moduledoc false
  use Ecto.Migration

  def change do
    create table(:resources, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:name, :string, null: false)
      add(:type, :string, null: false)
      add(:location, :string)
      add(:description, :text)

      # 🔗 사용자 소유 관계
      add(:user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(index(:resources, [:user_id]))
  end
end
