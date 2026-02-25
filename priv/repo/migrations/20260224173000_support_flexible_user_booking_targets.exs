defmodule AinComBooking.Repo.Migrations.SupportFlexibleUserBookingTargets do
  @moduledoc false
  use Ecto.Migration

  def up do
    alter table(:user_resources) do
      add(:price, :decimal, null: false, default: 0)
      add(:currency, :string, null: false, default: "KRW")
    end

    if !sqlite?() do
      create(
        constraint(
          :user_slots,
          :user_slots_service_or_resource_required,
          check: "(service_id IS NOT NULL) OR (resource_id IS NOT NULL)"
        )
      )
    end

    alter table(:user_bookings) do
      add(:service_id, references(:user_services, type: :binary_id, on_delete: :nilify_all))
      add(:resource_id, references(:user_resources, type: :binary_id, on_delete: :nilify_all))
      add(:service_price, :decimal, null: false, default: 0)
      add(:resource_price, :decimal, null: false, default: 0)
      add(:total_price, :decimal, null: false, default: 0)
      add(:currency, :string, null: false, default: "KRW")
    end

    execute("""
    UPDATE user_bookings AS b
    SET
      service_id = s.service_id,
      resource_id = s.resource_id
    FROM user_slots AS s
    WHERE b.slot_id = s.id
    """)

    execute("""
    UPDATE user_bookings AS b
    SET
      service_price = COALESCE(s.price, 0),
      currency = COALESCE(s.currency, b.currency, 'KRW')
    FROM user_services AS s
    WHERE b.service_id = s.id
    """)

    execute("""
    UPDATE user_bookings AS b
    SET
      resource_price = COALESCE(r.price, 0),
      currency = COALESCE(b.currency, r.currency, 'KRW')
    FROM user_resources AS r
    WHERE b.resource_id = r.id
    """)

    execute("""
    UPDATE user_bookings
    SET
      total_price = COALESCE(service_price, 0) + COALESCE(resource_price, 0),
      currency = COALESCE(currency, 'KRW')
    """)

    create(index(:user_bookings, [:service_id]))
    create(index(:user_bookings, [:resource_id]))

    if !sqlite?() do
      create(
        constraint(
          :user_bookings,
          :user_bookings_service_or_resource_required,
          check: "(service_id IS NOT NULL) OR (resource_id IS NOT NULL)"
        )
      )
    end
  end

  def down do
    if !sqlite?() do
      drop(constraint(:user_bookings, :user_bookings_service_or_resource_required))
    end

    drop(index(:user_bookings, [:resource_id]))
    drop(index(:user_bookings, [:service_id]))

    alter table(:user_bookings) do
      remove(:currency)
      remove(:total_price)
      remove(:resource_price)
      remove(:service_price)
      remove(:resource_id)
      remove(:service_id)
    end

    if !sqlite?() do
      drop(constraint(:user_slots, :user_slots_service_or_resource_required))
    end

    alter table(:user_resources) do
      remove(:currency)
      remove(:price)
    end
  end

  defp sqlite? do
    repo().__adapter__() == Ecto.Adapters.SQLite3
  end
end
