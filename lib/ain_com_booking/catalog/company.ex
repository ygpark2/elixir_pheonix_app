defmodule AinComBooking.Catalog.Company do
  @moduledoc false
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "companies" do
    field(:login, :string)
    field(:name, :string)
    field(:description_html, :string)
    field(:description_text, :string)
    field(:address1, :string)
    field(:address2, :string)
    field(:city, :string)
    field(:country_id, :string)
    field(:latitude, :decimal)
    field(:longitude, :decimal)
    field(:email, :string)
    field(:phone, :string)
    field(:web, :string)
    field(:logo, :string)
    field(:timezone, :string)
    field(:show_in_client_timezone, :boolean)
    field(:timeframe, :integer)
    field(:timeline_type, :string)
    field(:allow_event_day_break, :boolean)
    field(:allow_event_breaktime_break, :boolean)

    belongs_to(:user, AinComBooking.Accounts.User, type: :binary_id)

    has_many(:units, AinComBooking.Catalog.Unit)
    has_many(:services, AinComBooking.Catalog.CompanyService)
    has_many(:resources, AinComBooking.Catalog.CompanyResource)

    timestamps()
  end
end
