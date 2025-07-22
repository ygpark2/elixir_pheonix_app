defmodule AinComBookingApi.Bookings.Booking do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  alias AinComBookingApi.Bookings.Slot

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "bookings" do
    field(:customer_name, :string)
    field(:email, :string)
    field(:phone, :string)
    field(:status, :string, default: "confirmed")

    belongs_to(:slot, Slot, type: :binary_id)

    timestamps()
  end

  def changeset(booking, attrs) do
    booking
    |> cast(attrs, [:customer_name, :email, :phone, :status, :slot_id])
    |> validate_required([:customer_name, :email, :phone, :status, :slot_id])
    |> validate_inclusion(:status, ["confirmed", "cancelled", "noshow"])
    |> assoc_constraint(:slot)
  end
end
