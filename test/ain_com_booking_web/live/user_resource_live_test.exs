defmodule AinComBookingWeb.UserResourceLiveTest do
  use AinComBookingWeb.ConnCase, async: false

  import AinComBooking.AccountsFixtures
  import Phoenix.LiveViewTest

  alias AinComBooking.Catalog.UserResource
  alias AinComBooking.Repo

  describe "user resource live" do
    test "supports create, read, update, and delete on separate pages", %{conn: conn} do
      user = user_fixture(%{name: "Resource Owner"})
      conn = log_in_user(conn, user)

      {:ok, lv, html} = live(conn, ~p"/resources")
      assert html =~ "My Resources"
      assert has_element?(lv, ~s(a[href="/services"]))

      lv
      |> element(~s(a[href="/resources/new"]))
      |> render_click()

      assert_patch(lv, ~p"/resources/new")
      assert render(lv) =~ "Create Resource"

      lv
      |> form("#resource-form",
        resource: %{
          name: "Studio A",
          type: "room",
          location: "Seoul",
          description: "Bright room",
          price: "35.00",
          currency: "KRW"
        }
      )
      |> render_submit()

      resource = Repo.get_by!(UserResource, name: "Studio A", user_id: user.id)

      assert_patch(lv, ~p"/resources/#{resource.id}")
      assert render(lv) =~ "Bright room"

      lv
      |> element(~s(a[href="/resources/#{resource.id}/edit"]))
      |> render_click()

      assert_patch(lv, ~p"/resources/#{resource.id}/edit")

      lv
      |> form("#resource-form",
        resource: %{
          name: "Studio B",
          type: "room",
          location: "Busan",
          description: "Updated room",
          price: "45.00",
          currency: "KRW"
        }
      )
      |> render_submit()

      assert_patch(lv, ~p"/resources/#{resource.id}")
      assert render(lv) =~ "Studio B"
      assert Repo.get!(UserResource, resource.id).name == "Studio B"

      lv
      |> element(~s(a[href="/resources/#{resource.id}/delete"]))
      |> render_click()

      assert_patch(lv, ~p"/resources/#{resource.id}/delete")
      assert render(lv) =~ "Delete Resource"

      lv
      |> element(~s(button[phx-click="confirm_delete"]))
      |> render_click()

      assert_patch(lv, ~p"/resources")
      assert render(lv) =~ "Resource deleted."
      assert Repo.get(UserResource, resource.id) == nil
    end
  end
end
