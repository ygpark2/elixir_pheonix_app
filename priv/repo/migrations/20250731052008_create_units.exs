defmodule AinComBooking.Repo.Migrations.CreateUnits do
  @moduledoc false
  use Ecto.Migration

  def change do
    create table(:units, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:name, :string)
      add(:email, :string)
      add(:phone, :string)
      add(:description, :text)
      add(:picture, :string)
      add(:picture_path, :string)
      add(:position, :integer)
      add(:qty, :integer)
      add(:is_active, :boolean)
      add(:is_visible, :boolean)

      add(:company_id, references(:companies, type: :binary_id, on_delete: :delete_all))

      timestamps()
    end
  end
end
