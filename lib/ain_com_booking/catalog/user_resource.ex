defmodule AinComBooking.Catalog.UserResource do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "user_resources" do
    field(:name, :string)
    field(:type, :string)
    field(:location, :string)
    field(:description, :string)
    field(:price, :decimal)
    field(:currency, :string)

    belongs_to(:user, AinComBooking.Accounts.User, type: :binary_id)

    many_to_many(:units, AinComBooking.Catalog.Unit, join_through: "resources_units", join_keys: [resource_id: :id, unit_id: :id], on_replace: :delete)

    has_many(:slots, AinComBooking.Bookings.UserSlot, foreign_key: :resource_id)

    timestamps()
  end

  def changeset(resource, attrs) do
    resource
    |> cast(attrs, [:name, :type, :location, :description, :price, :currency, :user_id])
    |> validate_required([:name, :type, :price, :currency, :user_id])
    |> validate_number(:price, greater_than_or_equal_to: 0)
  end
end
