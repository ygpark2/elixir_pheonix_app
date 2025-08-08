defmodule AinComBooking.Catalog.Unit do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

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

    many_to_many(:services, AinComBooking.Catalog.CompanyService, join_through: "services_units", join_keys: [unit_id: :id, service_id: :id], on_replace: :delete)
    many_to_many(:resources, AinComBooking.Catalog.CompanyResource, join_through: "resources_units", join_keys: [unit_id: :id, resource_id: :id], on_replace: :delete)

    has_many(:slots, AinComBooking.Bookings.CompanySlot)

    timestamps()
  end

  def changeset(unit, attrs) do
    unit
    |> cast(attrs, [
      :name,
      :email,
      :phone,
      :description,
      :picture,
      :picture_path,
      :position,
      :qty,
      :is_active,
      :is_visible,
      :company_id
    ])
    |> validate_required([:name, :company_id])
  end
end
