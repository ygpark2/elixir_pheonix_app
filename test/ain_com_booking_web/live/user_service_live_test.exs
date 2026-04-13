defmodule AinComBookingWeb.UserServiceLiveTest do
  use AinComBookingWeb.ConnCase, async: false

  import AinComBooking.AccountsFixtures
  import Phoenix.LiveViewTest

  alias AinComBooking.Catalog.UserService
  alias AinComBooking.Repo

  describe "user service live" do
    test "supports create, read, update, and delete on separate pages", %{conn: conn} do
      user = user_fixture(%{name: "Service Owner"})
      conn = log_in_user(conn, user)

      {:ok, lv, html} = live(conn, ~p"/services")
      assert html =~ "My Services"
      assert has_element?(lv, ~s(a[href="/resources"]))

      lv
      |> element(~s(a[href="/services/new"]))
      |> render_click()

      assert_patch(lv, ~p"/services/new")
      assert render(lv) =~ "Create Service"

      lv
      |> form("#service-form",
        service: %{
          name: "Strategy Call",
          description_text: "One hour deep dive",
          duration: "60",
          price: "99.50",
          currency: "USD"
        }
      )
      |> render_submit()

      service = Repo.get_by!(UserService, name: "Strategy Call")

      assert_patch(lv, ~p"/services/#{service.id}")
      assert render(lv) =~ "One hour deep dive"

      lv
      |> element(~s(a[href="/services/#{service.id}/edit"]))
      |> render_click()

      assert_patch(lv, ~p"/services/#{service.id}/edit")

      lv
      |> form("#service-form",
        service: %{
          name: "VIP Strategy Call",
          description_text: "Updated",
          duration: "90",
          price: "149.00",
          currency: "USD",
          is_active: "true",
          is_public: "true"
        }
      )
      |> render_submit()

      assert_patch(lv, ~p"/services/#{service.id}")
      assert render(lv) =~ "VIP Strategy Call"
      assert Repo.get!(UserService, service.id).name == "VIP Strategy Call"

      lv
      |> element(~s(a[href="/services/#{service.id}/delete"]))
      |> render_click()

      assert_patch(lv, ~p"/services/#{service.id}/delete")
      assert render(lv) =~ "Delete Service"

      lv
      |> element(~s(button[phx-click="confirm_delete"]))
      |> render_click()

      assert_patch(lv, ~p"/services")
      assert render(lv) =~ "Service deleted."
      assert Repo.get(UserService, service.id) == nil
    end
  end
end
