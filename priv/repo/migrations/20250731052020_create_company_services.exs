defmodule AinComBooking.Repo.Migrations.CreateCompanyServices do
  @moduledoc false
  use Ecto.Migration

  def change do
    create table(:company_services, primary_key: false) do
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

      add(:company_id, references(:companies, type: :binary_id, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(index(:company_services, [:company_id]))
  end
end
