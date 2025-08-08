defmodule AinComBooking.Scheduling.DayOff do
  @moduledoc false
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "day_offs" do
    field(:owner_type, Ecto.Enum, values: [:company, :unit, :user])
    field(:date, :date)
    field(:reason, :string)

    belongs_to(:user, AinComBooking.Accounts.User, type: :binary_id)

    timestamps()
  end
end
