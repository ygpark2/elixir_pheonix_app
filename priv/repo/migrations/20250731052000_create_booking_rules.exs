defmodule AinComBooking.Repo.Migrations.CreateBookingRules do
  @moduledoc false
  use Ecto.Migration

  def change do
    create table(:booking_rules, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:target_type, :string)
      add(:target_id, :binary_id)
      add(:max_count, :integer)
      add(:is_enabled, :boolean)

      timestamps()
    end
  end
end
