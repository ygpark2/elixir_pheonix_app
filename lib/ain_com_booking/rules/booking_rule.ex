defmodule AinComBooking.Rules.BookingRule do
  @moduledoc false
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "booking_rules" do
    field(:target_type, Ecto.Enum, values: [:company, :unit, :service])
    field(:target_id, :binary_id)
    field(:max_count, :integer)
    field(:is_enabled, :boolean)

    timestamps()
  end
end
