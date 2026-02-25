defmodule AinComBooking.Repo.Migrations.AddProfileFieldsToUsers do
  @moduledoc false
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:name, :string, null: false, default: "")
      add(:phone, :string, null: false, default: "")
      add(:address, :string, null: false, default: "")
    end
  end
end
