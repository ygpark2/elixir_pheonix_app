defmodule AinComBooking.Repo.Migrations.EnforceProfileFieldsNonEmpty do
  @moduledoc false
  use Ecto.Migration

  def change do
    execute("UPDATE users SET name = 'Unknown' WHERE name = ''")
    execute("UPDATE users SET phone = 'Unknown' WHERE phone = ''")
    execute("UPDATE users SET address = 'Unknown' WHERE address = ''")

    if repo().__adapter__() == Ecto.Adapters.SQLite3 do
      :ok
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
