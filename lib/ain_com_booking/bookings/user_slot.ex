defmodule AinComBooking.Bookings.UserSlot do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "user_slots" do
    field(:start_time, :utc_datetime)
    field(:end_time, :utc_datetime)
    field(:status, Ecto.Enum, values: [:available, :booked, :cancelled])

    belongs_to(:service, AinComBooking.Catalog.UserService, type: :binary_id)
    belongs_to(:resource, AinComBooking.Catalog.UserResource, type: :binary_id)

    has_many(:bookings, AinComBooking.Bookings.UserBooking, foreign_key: :slot_id)

    timestamps()
  end

  def changeset(slot, attrs) do
    slot
    |> cast(attrs, [:start_time, :end_time, :status, :service_id, :resource_id])
    |> validate_required([:start_time, :end_time, :status])
    |> validate_service_or_resource_present()
    |> validate_end_time_after_start_time()
    |> foreign_key_constraint(:service_id)
    |> foreign_key_constraint(:resource_id)
    |> check_constraint(:service_id, name: :user_slots_service_or_resource_required)
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

  defp validate_end_time_after_start_time(changeset) do
    start_time = get_field(changeset, :start_time)
    end_time = get_field(changeset, :end_time)

    if is_nil(start_time) or is_nil(end_time) or DateTime.after?(end_time, start_time) do
      changeset
    else
      add_error(changeset, :end_time, "must be after start_time")
    end
  end
end
