defmodule AinComBookingApi.Devices.Device do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "devices" do
    field :token_hash, :string
    field :fingerprint, :string
    field :name, :string
    field :os, :string
    field :version, :string
    field :user_agent, :string
    field :ip, :string
    field :last_seen_at, :utc_datetime_usec
    field :revoked_at, :utc_datetime_usec
    field :expires_at, :utc_datetime_usec

    belongs_to :user, AinComBooking.Accounts.User

    timestamps()
  end

  def changeset(device, attrs) do
    device
    |> cast(attrs, [
      :token_hash,
      :fingerprint,
      :name,
      :os,
      :version,
      :user_id,
      :user_agent,
      :ip,
      :last_seen_at,
      :revoked_at,
      :expires_at
    ])
    |> validate_required([:token_hash, :user_id])
    |> unique_constraint(:token_hash)
    |> unique_constraint([:user_id, :fingerprint])
  end
end
