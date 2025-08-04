defmodule AinComBooking.Scheduling.DayOff do
  @moduledoc false
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "day_offs" do
    field(:owner_type, Ecto.Enum, values: [:company, :unit])
    field(:owner_id, :binary_id)
    field(:date, :date)
    field(:reason, :string)

    timestamps()
  end
end
