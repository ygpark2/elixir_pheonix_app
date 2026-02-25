defmodule AinComBooking.Bookings.UserBooking do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  alias AinComBooking.Bookings.UserSlot

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "user_bookings" do
    field(:customer_name, :string)
    field(:email, :string)
    field(:phone, :string)
    field(:status, :string, default: "confirmed")
    field(:service_price, :decimal)
    field(:resource_price, :decimal)
    field(:total_price, :decimal)
    field(:currency, :string)

    belongs_to(:slot, UserSlot, type: :binary_id)
    belongs_to(:service, AinComBooking.Catalog.UserService, type: :binary_id)
    belongs_to(:resource, AinComBooking.Catalog.UserResource, type: :binary_id)

    timestamps()
  end

  def changeset(booking, attrs) do
    booking
    |> cast(attrs, [
      :customer_name,
      :email,
      :phone,
      :status,
      :slot_id,
      :service_id,
      :resource_id,
      :service_price,
      :resource_price,
      :total_price,
      :currency
    ])
    |> validate_required([:customer_name, :email, :phone, :status, :slot_id, :total_price, :currency])
    |> validate_service_or_resource_present()
    |> validate_inclusion(:status, ["confirmed", "cancelled", "noshow"])
    |> validate_number(:service_price, greater_than_or_equal_to: 0)
    |> validate_number(:resource_price, greater_than_or_equal_to: 0)
    |> validate_number(:total_price, greater_than_or_equal_to: 0)
    |> assoc_constraint(:slot)
    |> assoc_constraint(:service)
    |> assoc_constraint(:resource)
    |> check_constraint(:service_id, name: :user_bookings_service_or_resource_required)
  end

  defp validate_service_or_resource_present(changeset) do
    service_id = get_field(changeset, :service_id)
    resource_id = get_field(changeset, :resource_id)

    if is_nil(service_id) and is_nil(resource_id) do
      changeset
      |> add_error(:service_id, "either service_id or resource_id is required")
      |> add_error(:resource_id, "either service_id or resource_id is required")
    else
      changeset
    end
  end
end
