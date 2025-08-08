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

    belongs_to(:slot, UserSlot, type: :binary_id)

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
