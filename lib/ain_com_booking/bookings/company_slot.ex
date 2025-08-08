defmodule AinComBooking.Bookings.CompanySlot do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "company_slots" do
    field(:date, :date)
    field(:start_time, :time)
    field(:end_time, :time)
    field(:status, Ecto.Enum, values: [:available, :booked, :cancelled])
    field(:capacity, :integer)
    field(:booked_count, :integer, default: 0)

    belongs_to(:company, AinComBooking.Catalog.Company, type: :binary_id)
    belongs_to(:unit, AinComBooking.Catalog.Unit, type: :binary_id)
    belongs_to(:service, AinComBooking.Catalog.CompanyService, type: :binary_id)
    belongs_to(:resource, AinComBooking.Catalog.CompanyResource, type: :binary_id)

    has_many(:bookings, AinComBooking.Bookings.CompanyBooking, foreign_key: :slot_id)

    timestamps()
  end

  def changeset(slot, attrs) do
    slot
    |> cast(attrs, [:start_time, :end_time, :status])
    |> validate_required([:start_time, :end_time, :status])
    |> validate_inclusion(:status, ["available", "booked", "cancelled"])
  end
end
