defmodule AinComBooking.Repo.Migrations.CreateUsersAuthTables do
  @moduledoc false
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:email, :string, null: false)
      add(:hashed_password, :string, null: false)
      add(:confirmed_at, :naive_datetime)

      timestamps()
    end

    if sqlite?() do
      create_sqlite_lowercase_email_triggers()
    else
      create(constraint(:users, :users_email_lowercase, check: "email = lower(email)"))
    end

    create(unique_index(:users, [:email]))

    create table(:users_tokens, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:token, :binary, null: false)
      add(:context, :string, null: false)
      add(:sent_to, :string)

      add(:user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false)

      timestamps(updated_at: false)
    end

    create(index(:users_tokens, [:user_id]))
    create(unique_index(:users_tokens, [:context, :token]))
  end

  defp sqlite? do
    repo().__adapter__() == Ecto.Adapters.SQLite3
  end

  defp create_sqlite_lowercase_email_triggers do
    execute(
      """
      CREATE TRIGGER users_email_lowercase_insert
      BEFORE INSERT ON users
      FOR EACH ROW
      WHEN NEW.email IS NULL OR NEW.email != lower(NEW.email)
      BEGIN
        SELECT RAISE(ABORT, 'email must be lowercase');
      END
      """,
      "DROP TRIGGER IF EXISTS users_email_lowercase_insert"
    )

    execute(
      """
      CREATE TRIGGER users_email_lowercase_update
      BEFORE UPDATE ON users
      FOR EACH ROW
      WHEN NEW.email IS NULL OR NEW.email != lower(NEW.email)
      BEGIN
        SELECT RAISE(ABORT, 'email must be lowercase');
      END
      """,
      "DROP TRIGGER IF EXISTS users_email_lowercase_update"
    )
  end
end
