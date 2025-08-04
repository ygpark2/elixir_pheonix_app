defmodule AinComBooking.Catalog.UserService do
  @moduledoc false
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "services" do
    field(:name, :string)
    field(:description_html, :string)
    field(:description_text, :string)
    field(:duration, :integer)
    field(:hide_duration, :boolean)
    field(:picture, :string)
    field(:picture_path, :string)
    field(:position, :integer)
    field(:is_active, :boolean)
    field(:is_public, :boolean)
    field(:is_recurring, :boolean)
    field(:price, :decimal)
    field(:currency, :string)

    belongs_to(:user, AinComBooking.Accounts.User, type: :binary_id)
    belongs_to(:company, AinComBooking.Catalog.Company, type: :binary_id)

    many_to_many(:units, AinComBooking.Catalog.Unit, join_through: "services_units", join_keys: [service_id: :id, unit_id: :id], on_replace: :delete)

    has_many(:slots, AinComBooking.Bookings.Slot)

    timestamps()
  end
end
