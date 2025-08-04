
defmodule AinComBooking.Repo.Migrations.CreateBreakTimes do
  use Ecto.Migration

  def change do
    create table(:break_times, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :owner_type, :string
      add :owner_id, :binary_id
      add :weekday, :string
      add :start_time, :time
      add :end_time, :time

      timestamps()
    end
  end
end
