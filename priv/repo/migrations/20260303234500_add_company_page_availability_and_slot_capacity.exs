defmodule AinComBooking.Repo.Migrations.AddCompanyPageAvailabilityAndSlotCapacity do
  @moduledoc false
  use Ecto.Migration

  def up do
    if sqlite?() do
      recreate_company_slots_sqlite()
      recreate_company_bookings_sqlite()
    else
      alter table(:company_slots) do
        add(:booking_page_id, references(:company_booking_pages, type: :binary_id, on_delete: :delete_all))
      end
    end

    create(index(:company_slots, [:booking_page_id]))
    create(index(:company_slots, [:booking_page_id, :source_type, :start_time]))
  end

  def down do
    drop(index(:company_slots, [:booking_page_id, :source_type, :start_time]))
    drop(index(:company_slots, [:booking_page_id]))

    if sqlite?() do
      recreate_company_slots_sqlite(:down)
      recreate_company_bookings_sqlite()
    else
      alter table(:company_slots) do
        remove(:booking_page_id)
      end
    end
  end

  defp recreate_company_slots_sqlite(direction \\ :up) do
    drop_sqlite_target_presence_triggers("company_slots", "company_slots_service_or_resource_required")
    rename(table(:company_slots), to: table(:company_slots_legacy))
    drop_if_exists(index(:company_slots_legacy, [:resource_id, :service_id], name: :company_slots_resource_id_service_id_index))

    create table(:company_slots, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:start_time, :utc_datetime, null: false)
      add(:end_time, :utc_datetime, null: false)
      add(:status, :string, null: false, default: "available")
      add(:source_type, :string, null: false, default: "manual")
      add(:max_bookings, :integer, default: 1)
      add(:resource_id, references(:company_resources, type: :binary_id, on_delete: :delete_all))
      add(:service_id, references(:company_services, type: :binary_id, on_delete: :delete_all))

      if direction == :up do
        add(:booking_page_id, references(:company_booking_pages, type: :binary_id, on_delete: :delete_all))
      end

      timestamps()
    end

    create(index(:company_slots, [:resource_id, :service_id]))
    create_sqlite_target_presence_triggers("company_slots", "company_slots_service_or_resource_required")

    insert_company_slots_sqlite(direction)

    drop(table(:company_slots_legacy))
  end

  defp insert_company_slots_sqlite(:up) do
    execute("""
    INSERT INTO company_slots (
      id,
      start_time,
      end_time,
      status,
      resource_id,
      service_id,
      source_type,
      max_bookings,
      booking_page_id,
      inserted_at,
      updated_at
    )
    SELECT
      id,
      start_time,
      end_time,
      status,
      resource_id,
      service_id,
      source_type,
      max_bookings,
      NULL,
      inserted_at,
      updated_at
    FROM company_slots_legacy
    """)
  end

  defp insert_company_slots_sqlite(:down) do
    execute("""
    INSERT INTO company_slots (
      id,
      start_time,
      end_time,
      status,
      resource_id,
      service_id,
      source_type,
      max_bookings,
      inserted_at,
      updated_at
    )
    SELECT
      id,
      start_time,
      end_time,
      status,
      resource_id,
      service_id,
      source_type,
      max_bookings,
      inserted_at,
      updated_at
    FROM company_slots_legacy
    """)
  end

  defp sqlite? do
    repo().__adapter__() == Ecto.Adapters.SQLite3
  end

  defp recreate_company_bookings_sqlite do
    drop_sqlite_target_presence_triggers("company_bookings", "company_bookings_service_or_resource_required")
    rename(table(:company_bookings), to: table(:company_bookings_legacy))

    drop_if_exists(index(:company_bookings_legacy, [:slot_id, :user_id], name: :company_bookings_slot_id_user_id_index))
    drop_if_exists(index(:company_bookings_legacy, [:service_id], name: :company_bookings_service_id_index))
    drop_if_exists(index(:company_bookings_legacy, [:resource_id], name: :company_bookings_resource_id_index))

    create table(:company_bookings, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:customer_name, :string, null: false)
      add(:email, :string, null: false)
      add(:phone, :string, null: false)
      add(:status, :string, null: false, default: "confirmed")
      add(:slot_id, references(:company_slots, type: :binary_id, on_delete: :delete_all), null: false)
      add(:user_id, references(:users, type: :binary_id, on_delete: :nilify_all))
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
    create_sqlite_target_presence_triggers("company_bookings", "company_bookings_service_or_resource_required")

    execute("""
    INSERT INTO company_bookings (
      id,
      customer_name,
      email,
      phone,
      status,
      slot_id,
      user_id,
      service_id,
      resource_id,
      service_price,
      resource_price,
      total_price,
      currency,
      inserted_at,
      updated_at
    )
    SELECT
      id,
      customer_name,
      email,
      phone,
      status,
      slot_id,
      user_id,
      service_id,
      resource_id,
      service_price,
      resource_price,
      total_price,
      currency,
      inserted_at,
      updated_at
    FROM company_bookings_legacy
    """)

    drop(table(:company_bookings_legacy))
  end

  defp create_sqlite_target_presence_triggers(table_name, trigger_prefix) do
    execute("""
    CREATE TRIGGER #{trigger_prefix}_insert
    BEFORE INSERT ON #{table_name}
    FOR EACH ROW
    WHEN NEW.service_id IS NULL AND NEW.resource_id IS NULL
    BEGIN
      SELECT RAISE(ABORT, 'service_id or resource_id is required');
    END
    """)

    execute("""
    CREATE TRIGGER #{trigger_prefix}_update
    BEFORE UPDATE ON #{table_name}
    FOR EACH ROW
    WHEN NEW.service_id IS NULL AND NEW.resource_id IS NULL
    BEGIN
      SELECT RAISE(ABORT, 'service_id or resource_id is required');
    END
    """)
  end

  defp drop_sqlite_target_presence_triggers(_table_name, trigger_prefix) do
    execute("DROP TRIGGER IF EXISTS #{trigger_prefix}_insert")
    execute("DROP TRIGGER IF EXISTS #{trigger_prefix}_update")
  end
end
