defmodule AinComBooking.Repo.Migrations.CreateUserServices do
  @moduledoc false
  use Ecto.Migration

  def change do
    create table(:user_services, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:name, :string)
      add(:description_html, :text)
      add(:description_text, :text)
      add(:duration, :integer)
      add(:hide_duration, :boolean)
      add(:picture, :string)
      add(:picture_path, :string)
      add(:position, :integer)
      add(:is_active, :boolean)
      add(:is_public, :boolean)
      add(:is_recurring, :boolean)
      add(:price, :decimal)
      add(:currency, :string)

      add(:user_id, references(:companies, type: :binary_id, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(index(:user_services, [:user_id]))
  end
end
