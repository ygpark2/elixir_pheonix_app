
defmodule AinComBooking.Repo.Migrations.CreateDayOffs do
  use Ecto.Migration

  def change do
    create table(:day_offs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :owner_type, :string
      add :owner_id, :binary_id
      add :date, :date
      add :reason, :string

      timestamps()
    end
  end
end
