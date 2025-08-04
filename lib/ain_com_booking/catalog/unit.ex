defmodule AinComBooking.Catalog.Unit do
  @moduledoc false
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "units" do
    field(:name, :string)
    field(:email, :string)
    field(:phone, :string)
    field(:description, :string)
    field(:picture, :string)
    field(:picture_path, :string)
    field(:position, :integer)
    field(:qty, :integer)
    field(:is_active, :boolean)
    field(:is_visible, :boolean)

    belongs_to(:company, AinComBooking.Catalog.Company, type: :binary_id)

    many_to_many(:services, AinComBooking.Catalog.Service, join_through: "services_units", join_keys: [unit_id: :id, service_id: :id], on_replace: :delete)
    many_to_many(:resources, AinComBooking.Catalog.Resource, join_through: "resources_units", join_keys: [unit_id: :id, resource_id: :id], on_replace: :delete)

    has_many(:slots, AinComBooking.Bookings.Slot)

    timestamps()
  end
end
