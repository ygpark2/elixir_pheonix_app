defmodule AinComBooking.Scheduling.BreakTime do
  @moduledoc false
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "break_times" do
    field(:owner_type, Ecto.Enum, values: [:company, :unit, :user])
    field(:weekday, Ecto.Enum, values: [:mon, :tue, :wed, :thu, :fri, :sat, :sun])
    field(:start_time, :time)
    field(:end_time, :time)

    belongs_to(:user, AinComBooking.Accounts.User, type: :binary_id)

    timestamps()
  end
end
