defmodule AinComBooking.Repo.Migrations.CreateCompanyBookings do
  @moduledoc false
  use Ecto.Migration

  def change do
    # Create bookings table
    create table(:company_bookings, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:customer_name, :string, null: false)
      add(:email, :string, null: false)
      add(:phone, :string, null: false)
      add(:status, :string, null: false, default: "confirmed")

      add(:slot_id, references(:company_slots, type: :binary_id, on_delete: :delete_all), null: false)

      # 🔗 예약한 사용자 연결
      add(:user_id, references(:users, type: :binary_id, on_delete: :nilify_all), null: true)

      timestamps()
    end

    # Optional: Add index for foreign key
    create(index(:company_bookings, [:slot_id, :user_id]))
  end
end
