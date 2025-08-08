defmodule AinComBooking.Repo.Migrations.CreateCompanySlots do
  @moduledoc false
  use Ecto.Migration

  def change do
    # Create slots table first (referenced by bookings)
    create table(:company_slots, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:start_time, :utc_datetime, null: false)
      add(:end_time, :utc_datetime, null: false)
      add(:status, :string, null: false, default: "available")

      add(:resource_id, references(:company_resources, type: :binary_id, on_delete: :delete_all), null: false)
      add(:service_id, references(:company_services, type: :binary_id, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(index(:company_slots, [:resource_id, :service_id]))
  end
end
