defmodule AinComBooking.Social do
  @moduledoc false
  import Ecto.Query, warn: false

  alias AinComBooking.Accounts.Follow
  alias AinComBooking.Accounts.User
  alias AinComBooking.Repo

  @doc """
  Returns users visible in the social feed for the given viewer.

  Visibility rules:
  - `public`: visible to everyone
  - `followers`: visible only to followers of the target user
  - `link` and `private`: excluded from feed
  """
  def list_feed_users(%User{id: viewer_id}) when is_binary(viewer_id) do
    list_feed_users(viewer_id)
  end

  def list_feed_users(viewer_id) when is_binary(viewer_id) do
    Repo.all(
      from(u in User,
        left_join: f in Follow,
        on: f.followed_id == u.id and f.follower_id == ^viewer_id,
        where: u.id != ^viewer_id,
        where: u.feed_visibility == :public or (u.feed_visibility == :followers and not is_nil(f.follower_id)),
        order_by: [desc: u.inserted_at]
      )
    )
  end
end
