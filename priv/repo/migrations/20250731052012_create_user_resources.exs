defmodule AinComBooking.Repo.Migrations.CreateUserResources do
  @moduledoc false
  use Ecto.Migration

  def change do
    create table(:user_resources, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:name, :string, null: false)
      add(:type, :string, null: false)
      add(:location, :string)
      add(:description, :text)
      add(:price, :decimal, null: false, default: 0)
      add(:currency, :string, null: false, default: "KRW")

      add(:user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(index(:user_resources, [:user_id]))
  end
end
