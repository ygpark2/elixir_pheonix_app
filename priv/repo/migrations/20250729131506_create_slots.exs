defmodule AinComBooking.Repo.Migrations.CreateSlots do
  @moduledoc false
  use Ecto.Migration

  def change do
    # Create slots table first (referenced by bookings)
    create table(:slots, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:start_time, :utc_datetime, null: false)
      add(:end_time, :utc_datetime, null: false)
      add(:status, :string, null: false, default: "available")

      add(:resource_id, references(:resources, type: :binary_id, on_delete: :delete_all), null: false)

      timestamps()
    end
  end
end
