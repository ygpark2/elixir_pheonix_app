defmodule AinComBooking.Scheduling.WorkingHour do
  @moduledoc false
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "working_hours" do
    field(:owner_type, Ecto.Enum, values: [:company, :unit, :user])
    field(:weekday, Ecto.Enum, values: [:mon, :tue, :wed, :thu, :fri, :sat, :sun])
    field(:start_time, :time)
    field(:end_time, :time)
    field(:is_day_off, :boolean)

    belongs_to(:user, AinComBooking.Accounts.User, type: :binary_id)

    timestamps()
  end
end
