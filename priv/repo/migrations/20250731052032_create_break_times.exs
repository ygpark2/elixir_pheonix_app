defmodule AinComBooking.Repo.Migrations.CreateBreakTimes do
  @moduledoc false
  use Ecto.Migration

  def change do
    create table(:break_times, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:owner_type, :string)
      add(:weekday, :string)
      add(:start_time, :time)
      add(:end_time, :time)

      add(:user_id, references(:users, type: :binary_id, on_delete: :nilify_all), null: false)

      timestamps()
    end

    create(index(:break_times, [:user_id]))
  end
end
