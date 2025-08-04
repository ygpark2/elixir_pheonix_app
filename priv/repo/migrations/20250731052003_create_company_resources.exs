defmodule AinComBooking.Repo.Migrations.CreateCompanyResources do
  @moduledoc false
  use Ecto.Migration

  def change do
    create table(:company_resources, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:name, :string, null: false)
      add(:type, :string, null: false)
      add(:location, :string)
      add(:description, :text)

      # 🔗 사용자 소유 관계
      add(:company_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(index(:company_resources, [:company_id]))
  end
end
