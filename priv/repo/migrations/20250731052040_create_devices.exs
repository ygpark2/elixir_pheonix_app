defmodule AinComBooking.Repo.Migrations.CreateDevices do
  use Ecto.Migration

  def change do
    create table(:devices, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :token_hash, :string, null: false
      add :fingerprint, :string
      add :name, :string
      add :os, :string
      add :version, :string
      add :user_agent, :text
      add :ip, :string
      add :last_seen_at, :utc_datetime_usec
      add :revoked_at, :utc_datetime_usec
      add :expires_at, :utc_datetime_usec
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:devices, [:token_hash])
    create index(:devices, [:user_id])
    create unique_index(:devices, [:user_id, :fingerprint])
    create index(:devices, [:revoked_at])
    create index(:devices, [:expires_at])
  end
end
