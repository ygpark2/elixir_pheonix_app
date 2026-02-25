defmodule AinComBookingWeb.UserProfileLiveTest do
  use AinComBookingWeb.ConnCase, async: false

  import AinComBooking.AccountsFixtures
  import Phoenix.LiveViewTest

  describe "User profile follow" do
    test "toggles follow state", %{conn: conn} do
      current_user = user_fixture(%{email: "current@example.com"})
      target_user = user_fixture(%{name: "Target User"})

      conn = log_in_user(conn, current_user)

      {:ok, lv, html} = live(conn, ~p"/profiles/#{target_user.id}")

      assert html =~ "Target User"
      assert html =~ "Not following"

      html = lv |> element("#follow-toggle") |> render_click()
      assert html =~ "Following"
      assert html =~ "Unfollow"
      assert html =~ "Follower schedule visible"

      html = lv |> element("#follow-toggle") |> render_click()
      assert html =~ "Not following"
      assert html =~ "Follow"
    end

    test "redirects if user is not logged in", %{conn: conn} do
      target_user = user_fixture()

      assert {:error, redirect} = live(conn, ~p"/profiles/#{target_user.id}")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log_in"
      assert %{"error" => "You must log in to access this page."} = flash
    end
  end
end
