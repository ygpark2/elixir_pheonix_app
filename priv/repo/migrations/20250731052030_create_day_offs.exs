defmodule AinComBooking.Repo.Migrations.CreateDayOffs do
  @moduledoc false
  use Ecto.Migration

  def change do
    create table(:day_offs, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:owner_type, :string)
      add(:date, :date)
      add(:reason, :string)

      add(:user_id, references(:users, type: :binary_id, on_delete: :nilify_all), null: false)

      timestamps()
    end

    create(index(:day_offs, [:user_id]))
  end
end
