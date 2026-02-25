defmodule AinComBooking.Repo.Migrations.AddTelemetryUiEventsTable do
  @moduledoc false
  use Ecto.Migration

  alias Ecto.Adapters.Postgres
  alias TelemetryUI.Backend.EctoPostgres.Migrations

  @disable_migration_lock true
  @disable_ddl_transaction true

  def up do
    if repo().__adapter__() == Postgres do
      Migrations.up()
    end
  end

  # We specify `version: 1` in `down`, ensuring that we'll roll all the way back down if
  # necessary, regardless of which version we've migrated `up` to.
  def down do
    if repo().__adapter__() == Postgres do
      Migrations.down(version: 1)
    end
  end
end
