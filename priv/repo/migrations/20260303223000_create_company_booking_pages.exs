defmodule AinComBooking.Repo.Migrations.CreateCompanyBookingPages do
  @moduledoc false
  use Ecto.Migration

  def change do
    create table(:company_booking_pages, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:title, :string, null: false)
      add(:description, :text)
      add(:button_label, :string, null: false, default: "Book now")
      add(:slug, :string, null: false)
      add(:theme, :string, null: false, default: "brand")
      add(:is_published, :boolean, null: false, default: true)
      add(:auto_slots_enabled, :boolean, null: false, default: false)
      add(:schedule_start_date, :date)
      add(:schedule_end_date, :date)
      add(:work_start_time, :time)
      add(:work_end_time, :time)
      add(:slot_minutes, :integer, null: false, default: 60)
      add(:break_minutes, :integer, null: false, default: 10)
      add(:lunch_start_time, :time)
      add(:lunch_end_time, :time)
      add(:available_weekdays, :string, null: false, default: "mon,tue,wed,thu,fri")
      add(:excluded_dates, :text, null: false, default: "")
      add(:default_max_bookings, :integer)

      add(:company_id, references(:companies, type: :binary_id, on_delete: :delete_all), null: false)
      add(:service_id, references(:company_services, type: :binary_id, on_delete: :delete_all))
      add(:resource_id, references(:company_resources, type: :binary_id, on_delete: :delete_all))

      timestamps()
    end

    create(unique_index(:company_booking_pages, [:slug]))
    create(index(:company_booking_pages, [:company_id, :inserted_at]))
    create(index(:company_booking_pages, [:service_id]))
    create(index(:company_booking_pages, [:resource_id]))

    if sqlite?() do
      create_sqlite_target_presence_triggers(
        "company_booking_pages",
        "company_booking_pages_service_or_resource_required"
      )
    else
      create(
        constraint(
          :company_booking_pages,
          :company_booking_pages_service_or_resource_required,
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
