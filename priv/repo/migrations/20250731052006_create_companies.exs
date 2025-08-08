defmodule AinComBooking.Repo.Migrations.CreateCompanies do
  @moduledoc false
  use Ecto.Migration

  def change do
    create table(:companies, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:login, :string)
      add(:name, :string)
      add(:description_html, :text)
      add(:description_text, :text)
      add(:address1, :string)
      add(:address2, :string)
      add(:city, :string)
      add(:country_id, :string)
      add(:latitude, :decimal)
      add(:longitude, :decimal)
      add(:email, :string)
      add(:phone, :string)
      add(:web, :string)
      add(:logo, :string)
      add(:timezone, :string)
      add(:show_in_client_timezone, :boolean)
      add(:timeframe, :integer)
      add(:timeline_type, :string)
      add(:allow_event_day_break, :boolean)
      add(:allow_event_breaktime_break, :boolean)

      add(:user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false)

      timestamps()
    end
  end
end
