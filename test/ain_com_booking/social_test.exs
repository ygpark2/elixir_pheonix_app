defmodule AinComBooking.SocialTest do
  use AinComBooking.DataCase, async: false

  import AinComBooking.AccountsFixtures

  alias AinComBooking.Accounts
  alias AinComBooking.Social

  describe "list_feed_users/1" do
    test "returns public users and followed followers-only users" do
      viewer = user_fixture(%{name: "Viewer"})
      _public_user = user_fixture(%{name: "Public User", feed_visibility: :public})
      followers_user = user_fixture(%{name: "Followers User", feed_visibility: :followers})
      _private_user = user_fixture(%{name: "Private User", feed_visibility: :private})
      _link_user = user_fixture(%{name: "Link User", feed_visibility: :link})

      assert {:ok, _follow} = Accounts.follow_user(viewer, followers_user)

      names =
        viewer
        |> Social.list_feed_users()
        |> Enum.map(& &1.name)

      assert "Public User" in names
      assert "Followers User" in names
      refute "Private User" in names
      refute "Link User" in names
      refute "Viewer" in names
    end

    test "does not return followers-only users when viewer is not following" do
      viewer = user_fixture(%{name: "Viewer"})
      followers_user = user_fixture(%{name: "Followers User", feed_visibility: :followers})

      ids =
        viewer
        |> Social.list_feed_users()
        |> Enum.map(& &1.id)

      refute followers_user.id in ids
    end
  end
end
