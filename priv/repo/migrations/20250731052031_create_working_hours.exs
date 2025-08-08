defmodule AinComBooking.Repo.Migrations.CreateWorkingHours do
  @moduledoc false
  use Ecto.Migration

  def change do
    create table(:working_hours, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:owner_type, :string)
      add(:weekday, :string)
      add(:start_time, :time)
      add(:end_time, :time)
      add(:is_day_off, :boolean)

      add(:user_id, references(:users, type: :binary_id, on_delete: :nilify_all), null: false)

      timestamps()
    end

    create(index(:working_hours, [:user_id]))
  end
end
