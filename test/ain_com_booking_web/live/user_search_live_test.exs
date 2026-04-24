defmodule AinComBookingWeb.UserSearchLiveTest do
  use AinComBookingWeb.ConnCase, async: false

  import AinComBooking.AccountsFixtures
  import Phoenix.LiveViewTest

  describe "User search" do
    test "renders results for a name query", %{conn: conn} do
      current_user = user_fixture(%{email: "current@example.com", name: "Current User"})
      _target_user = user_fixture(%{email: "target@example.com", name: "Search Target"})
      conn = log_in_user(conn, current_user)

      {:ok, lv, _html} = live(conn, ~p"/users/search")

      result =
        lv
        |> form("#user_search_form", %{"search" => %{"query" => "Search"}})
        |> render_change()

      assert result =~ "Search Target"
      refute result =~ "target@example.com"
    end

    test "renders empty state when no results", %{conn: conn} do
      current_user = user_fixture(%{email: "current@example.com", name: "Current User"})
      conn = log_in_user(conn, current_user)

      {:ok, lv, _html} = live(conn, ~p"/users/search")

      result =
        lv
        |> form("#user_search_form", %{"search" => %{"query" => "no-matches"}})
        |> render_change()

      assert result =~ "No results found"
    end

    test "hides follower-only users until the viewer follows them", %{conn: conn} do
      current_user = user_fixture(%{email: "viewer@example.com", name: "Viewer"})
      follower_only_user = user_fixture(%{
        email: "followers@example.com",
        name: "Followers Search Target",
        feed_visibility: :followers
      })

      conn = log_in_user(conn, current_user)

      {:ok, lv, _html} = live(conn, ~p"/users/search")

      result =
        lv
        |> form("#user_search_form", %{"search" => %{"query" => "Followers"}})
        |> render_change()

      refute result =~ "Followers Search Target"

      assert {:ok, _follow} = AinComBooking.Accounts.follow_user(current_user, follower_only_user)

      result =
        lv
        |> form("#user_search_form", %{"search" => %{"query" => "Followers"}})
        |> render_change()

      assert result =~ "Followers Search Target"
    end

    test "redirects if user is not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/users/search")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log_in"
      assert %{"error" => "You must log in to access this page."} = flash
    end
  end
end
