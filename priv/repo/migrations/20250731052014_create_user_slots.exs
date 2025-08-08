defmodule AinComBooking.Repo.Migrations.CreateUserSlots do
  @moduledoc false
  use Ecto.Migration

  def change do
    # Create slots table first (referenced by bookings)
    create table(:user_slots, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:start_time, :utc_datetime, null: false)
      add(:end_time, :utc_datetime, null: false)
      add(:status, :string, null: false, default: "available")

      add(:resource_id, references(:user_resources, type: :binary_id, on_delete: :delete_all), null: true)
      add(:service_id, references(:user_services, type: :binary_id, on_delete: :delete_all), null: true)

      timestamps()
    end

    create(index(:user_slots, [:resource_id, :service_id]))
  end
end
