defmodule AinComBooking.Accounts.Follow do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "follows" do
    field(:follower_id, :binary_id)
    field(:followed_id, :binary_id)

    timestamps()
  end

  def changeset(follow, attrs) do
    follow
    |> cast(attrs, [:follower_id, :followed_id])
    |> validate_required([:follower_id, :followed_id])
    |> validate_not_self_follow()
    |> unique_constraint(:followed_id, name: :follows_follower_id_followed_id_index)
  end

  defp validate_not_self_follow(changeset) do
    follower_id = get_field(changeset, :follower_id)
    followed_id = get_field(changeset, :followed_id)

    if follower_id && followed_id && follower_id == followed_id do
      add_error(changeset, :followed_id, "cannot follow yourself")
    else
      changeset
    end
  end
end
