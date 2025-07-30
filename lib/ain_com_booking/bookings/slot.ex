defmodule AinComBooking.Bookings.Slot do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "slots" do
    field(:start_time, :utc_datetime)
    field(:end_time, :utc_datetime)
    field(:status, :string, default: "available")

    timestamps()
  end

  def changeset(slot, attrs) do
    slot
    |> cast(attrs, [:start_time, :end_time, :status])
    |> validate_required([:start_time, :end_time, :status])
    |> validate_inclusion(:status, ["available", "booked", "cancelled"])
  end
end
