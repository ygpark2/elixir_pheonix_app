defmodule AinComBooking.Catalog.UserResource do
  @moduledoc false
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "user_resources" do
    field(:name, :string)
    field(:type, :string)
    field(:location, :string)
    field(:description, :string)

    belongs_to(:user, AinComBooking.Accounts.User, type: :binary_id)
    belongs_to(:company, AinComBooking.Catalog.Company, type: :binary_id)

    many_to_many(:units, AinComBooking.Catalog.Unit, join_through: "resources_units", join_keys: [resource_id: :id, unit_id: :id], on_replace: :delete)

    has_many(:slots, AinComBooking.Bookings.Slot)

    timestamps()
  end
end
