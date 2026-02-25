defmodule AinComBookingWeb.AdminDashboardLiveTest do
  use AinComBookingWeb.ConnCase, async: false

  import AinComBooking.AccountsFixtures
  import Phoenix.LiveViewTest

  alias AinComBooking.Accounts

  describe "admin dashboard" do
    test "renders dashboard metrics and profile table", %{conn: conn} do
      admin_user = user_fixture(%{name: "Admin User"})
      creator_a = user_fixture(%{name: "Creator A", feed_visibility: :public})
      creator_b = user_fixture(%{name: "Creator B", feed_visibility: :followers})

      assert {:ok, _} = Accounts.follow_user(admin_user, creator_a)
      assert {:ok, _} = Accounts.follow_user(creator_b, creator_a)

      conn = log_in_user(conn, admin_user)
      {:ok, _lv, html} = live(conn, ~p"/admin/dashboard")

      assert html =~ "Admin Dashboard"
      assert html =~ "Platform Overview"
      assert html =~ "Total Users"
      assert html =~ "Visibility Distribution"
      assert html =~ "Top Profiles"
      assert html =~ "Creator A"
    end

    test "redirects to login when user is not authenticated", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/admin/dashboard")
      assert {:redirect, %{to: path, flash: flash}} = redirect

      assert path == ~p"/users/log_in"
      assert %{"error" => "You must log in to access this page."} = flash
    end
  end
end
