defmodule AinComBooking.Repo.Migrations.CreateCompanyBookings do
  @moduledoc false
  use Ecto.Migration

  def change do
    create table(:company_bookings, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:customer_name, :string, null: false)
      add(:email, :string, null: false)
      add(:phone, :string, null: false)
      add(:status, :string, null: false, default: "confirmed")

      add(:slot_id, references(:company_slots, type: :binary_id, on_delete: :delete_all), null: false)
      add(:user_id, references(:users, type: :binary_id, on_delete: :nilify_all), null: true)
      add(:service_id, references(:company_services, type: :binary_id, on_delete: :nilify_all))
      add(:resource_id, references(:company_resources, type: :binary_id, on_delete: :nilify_all))
      add(:service_price, :decimal, null: false, default: 0)
      add(:resource_price, :decimal, null: false, default: 0)
      add(:total_price, :decimal, null: false, default: 0)
      add(:currency, :string, null: false, default: "KRW")

      timestamps()
    end

    create(index(:company_bookings, [:slot_id, :user_id]))
    create(index(:company_bookings, [:service_id]))
    create(index(:company_bookings, [:resource_id]))

    if sqlite?() do
      create_sqlite_target_presence_triggers("company_bookings", "company_bookings_service_or_resource_required")
    else
      create(
        constraint(
          :company_bookings,
          :company_bookings_service_or_resource_required,
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
