defmodule AinComBooking.Repo.Migrations.EnforceProfileFieldsNonEmpty do
  @moduledoc false
  use Ecto.Migration

  def change do
    execute("UPDATE users SET name = 'Unknown' WHERE name = ''")
    execute("UPDATE users SET phone = 'Unknown' WHERE phone = ''")
    execute("UPDATE users SET address = 'Unknown' WHERE address = ''")

    if repo().__adapter__() == Ecto.Adapters.SQLite3 do
      execute(
        """
        CREATE TRIGGER users_profile_fields_non_empty_insert
        BEFORE INSERT ON users
        FOR EACH ROW
        WHEN NEW.name IS NULL
          OR length(NEW.name) = 0
          OR NEW.phone IS NULL
          OR length(NEW.phone) = 0
          OR NEW.address IS NULL
          OR length(NEW.address) = 0
        BEGIN
          SELECT RAISE(ABORT, 'profile fields must not be empty');
        END
        """,
        "DROP TRIGGER IF EXISTS users_profile_fields_non_empty_insert"
      )

      execute(
        """
        CREATE TRIGGER users_profile_fields_non_empty_update
        BEFORE UPDATE ON users
        FOR EACH ROW
        WHEN NEW.name IS NULL
          OR length(NEW.name) = 0
          OR NEW.phone IS NULL
          OR length(NEW.phone) = 0
          OR NEW.address IS NULL
          OR length(NEW.address) = 0
        BEGIN
          SELECT RAISE(ABORT, 'profile fields must not be empty');
        END
        """,
        "DROP TRIGGER IF EXISTS users_profile_fields_non_empty_update"
      )
    else
      alter table(:users) do
        modify(:name, :string, null: false, default: nil)
        modify(:phone, :string, null: false, default: nil)
        modify(:address, :string, null: false, default: nil)
      end

      create(constraint(:users, :users_name_not_empty, check: "length(name) > 0"))
      create(constraint(:users, :users_phone_not_empty, check: "length(phone) > 0"))
      create(constraint(:users, :users_address_not_empty, check: "length(address) > 0"))
    end
  end
end
