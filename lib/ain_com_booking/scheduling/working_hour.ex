defmodule AinComBooking.Scheduling.WorkingHour do
  @moduledoc false
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "working_hours" do
    field(:owner_type, Ecto.Enum, values: [:company, :unit])
    field(:owner_id, :binary_id)
    field(:weekday, Ecto.Enum, values: [:mon, :tue, :wed, :thu, :fri, :sat, :sun])
    field(:start_time, :time)
    field(:end_time, :time)
    field(:is_day_off, :boolean)

    timestamps()
  end
end
