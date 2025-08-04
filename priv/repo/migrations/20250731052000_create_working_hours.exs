
defmodule AinComBooking.Repo.Migrations.CreateWorkingHours do
  use Ecto.Migration

  def change do
    create table(:working_hours, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :owner_type, :string
      add :owner_id, :binary_id
      add :weekday, :string
      add :start_time, :time
      add :end_time, :time
      add :is_day_off, :boolean

      timestamps()
    end
  end
end
