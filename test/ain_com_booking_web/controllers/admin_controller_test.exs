defmodule AinComBookingWeb.AdminControllerTest do
  use AinComBookingWeb.ConnCase, async: true

  import AinComBooking.AccountsFixtures

  describe "GET /admin" do
    test "redirects authenticated admin users to the admin dashboard", %{conn: conn} do
      user = user_fixture(%{role: :admin})

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/admin")

      assert redirected_to(conn) == ~p"/admin/dashboard"
    end

    test "redirects non-admin users away from the admin page", %{conn: conn} do
      user = user_fixture()

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/admin")

      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "You are not authorized to access this page."
    end

    test "redirects unauthenticated users to the login page", %{conn: conn} do
      conn = get(conn, ~p"/admin")

      assert redirected_to(conn) == ~p"/users/log_in"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "You must log in to access this page."
    end
  end
end
