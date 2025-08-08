defmodule AinComBooking.Catalog.CompanyService do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "company_services" do
    field(:name, :string)
    field(:description_html, :string)
    field(:description_text, :string)
    field(:duration, :integer)
    field(:hide_duration, :boolean)
    field(:picture, :string)
    field(:picture_path, :string)
    field(:position, :integer)
    field(:is_active, :boolean)
    field(:is_public, :boolean)
    field(:is_recurring, :boolean)
    field(:price, :decimal)
    field(:currency, :string)

    belongs_to(:user, AinComBooking.Accounts.User, type: :binary_id)
    belongs_to(:company, AinComBooking.Catalog.Company, type: :binary_id)

    many_to_many(:units, AinComBooking.Catalog.Unit, join_through: "services_units", join_keys: [service_id: :id, unit_id: :id], on_replace: :delete)

    has_many(:slots, AinComBooking.Bookings.CompanySlot, foreign_key: :service_id)

    timestamps()
  end

  @doc false
  def changeset(company_service, attrs) do
    company_service
    |> cast(attrs, [
      :name,
      :description_html,
      :description_text,
      :duration,
      :hide_duration,
      :picture,
      :picture_path,
      :position,
      :is_active,
      :is_public,
      :is_recurring,
      :price,
      :currency,
      :user_id,
      :company_id
    ])
    |> validate_required([:name, :duration, :price, :currency, :company_id])
  end
end
