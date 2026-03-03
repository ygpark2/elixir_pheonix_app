defmodule AinComBooking.Catalog.CompanyResource do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "company_resources" do
    field(:name, :string)
    field(:type, :string)
    field(:location, :string)
    field(:description, :string)
    field(:price, :decimal)
    field(:currency, :string)

    belongs_to(:company, AinComBooking.Catalog.Company, type: :binary_id)

    many_to_many(:units, AinComBooking.Catalog.Unit, join_through: "resources_units", join_keys: [resource_id: :id, unit_id: :id], on_replace: :delete)

    has_many(:slots, AinComBooking.Bookings.CompanySlot, foreign_key: :resource_id)

    timestamps()
  end

  @doc false
  def changeset(company_resource, attrs) do
    company_resource
    |> cast(attrs, [
      :name,
      :type,
      :location,
      :description,
      :price,
      :currency,
      :company_id
    ])
    |> validate_required([:name, :company_id, :price, :currency])
    |> validate_number(:price, greater_than_or_equal_to: 0)
  end
end
