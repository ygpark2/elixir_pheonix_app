defmodule AinComBooking.Repo.Migrations.AddRoleToUsers do
  @moduledoc false
  use Ecto.Migration

  def up do
    alter table(:users) do
      add(:role, :string, null: false, default: "user")
    end

    execute("UPDATE users SET role = 'admin' WHERE email = 'admin@ain.com'")
  end

  def down do
    alter table(:users) do
      remove(:role)
    end
  end
end
