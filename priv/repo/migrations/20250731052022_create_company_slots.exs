defmodule AinComBooking.Repo.Migrations.CreateCompanySlots do
  @moduledoc false
  use Ecto.Migration

  def change do
    create table(:company_slots, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:start_time, :utc_datetime, null: false)
      add(:end_time, :utc_datetime, null: false)
      add(:status, :string, null: false, default: "available")
      add(:source_type, :string, null: false, default: "manual")
      add(:max_bookings, :integer, default: 1)

      add(:resource_id, references(:company_resources, type: :binary_id, on_delete: :delete_all), null: true)
      add(:service_id, references(:company_services, type: :binary_id, on_delete: :delete_all), null: true)

      timestamps()
    end

    create(index(:company_slots, [:resource_id, :service_id]))

    if sqlite?() do
      create_sqlite_target_presence_triggers("company_slots", "company_slots_service_or_resource_required")
    else
      create(
        constraint(
          :company_slots,
          :company_slots_service_or_resource_required,
          check: "(service_id IS NOT NULL) OR (resource_id IS NOT NULL)"
        )
      )
    end
  end

  defp sqlite? do
    repo().__adapter__() == Ecto.Adapters.SQLite3
  end

  defp create_sqlite_target_presence_triggers(table_name, trigger_prefix) do
    execute(
      """
      CREATE TRIGGER #{trigger_prefix}_insert
      BEFORE INSERT ON #{table_name}
      FOR EACH ROW
      WHEN NEW.service_id IS NULL AND NEW.resource_id IS NULL
      BEGIN
        SELECT RAISE(ABORT, 'service_id or resource_id is required');
      END
      """,
      "DROP TRIGGER IF EXISTS #{trigger_prefix}_insert"
    )

    execute(
      """
      CREATE TRIGGER #{trigger_prefix}_update
      BEFORE UPDATE ON #{table_name}
      FOR EACH ROW
      WHEN NEW.service_id IS NULL AND NEW.resource_id IS NULL
      BEGIN
        SELECT RAISE(ABORT, 'service_id or resource_id is required');
      END
      """,
      "DROP TRIGGER IF EXISTS #{trigger_prefix}_update"
    )
  end
end
