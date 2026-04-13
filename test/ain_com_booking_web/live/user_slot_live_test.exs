defmodule AinComBookingWeb.UserSlotLiveTest do
  use AinComBookingWeb.ConnCase, async: false

  import AinComBooking.AccountsFixtures
  import Phoenix.LiveViewTest

  alias AinComBooking.Bookings.UserSlot
  alias AinComBooking.Catalog
  alias AinComBooking.Repo

  describe "user slot live" do
    test "supports create, read, update, and delete on separate pages", %{conn: conn} do
      user = user_fixture(%{name: "Slot Owner"})
      conn = log_in_user(conn, user)
      start_time = DateTime.utc_now() |> DateTime.add(24 * 60 * 60, :second) |> DateTime.truncate(:second)
      end_time = DateTime.add(start_time, 30 * 60, :second)
      updated_start_time = DateTime.add(start_time, 60 * 60, :second)
      updated_end_time = DateTime.add(updated_start_time, 45 * 60, :second)

      {:ok, resource} =
        Catalog.create_user_resource(user, %{
          "name" => "Consulting Room",
          "type" => "room",
          "location" => "Seoul",
          "description" => "Quiet room",
          "price" => "25.00",
          "currency" => "KRW"
        })

      {:ok, lv, html} = live(conn, ~p"/slots")
      assert html =~ "My Slots"
      assert has_element?(lv, ~s(a[href="/services"]))
      assert has_element?(lv, ~s(a[href="/resources"]))

      lv
      |> element(~s(a[href="/slots/new"]))
      |> render_click()

      assert_patch(lv, ~p"/slots/new")
      assert render(lv) =~ "Create Slot"

      lv
      |> form("#slot-form",
        slot: %{
          start_time: datetime_local_value(start_time),
          end_time: datetime_local_value(end_time),
          status: "available",
          resource_id: resource.id
        }
      )
      |> render_submit()

      slot = Repo.get_by!(UserSlot, resource_id: resource.id)

      assert_patch(lv, ~p"/slots/#{slot.id}")
      assert render(lv) =~ "Visible now"

      lv
      |> element(~s(a[href="/slots/#{slot.id}/edit"]))
      |> render_click()

      assert_patch(lv, ~p"/slots/#{slot.id}/edit")

      lv
      |> form("#slot-form",
        slot: %{
          start_time: datetime_local_value(updated_start_time),
          end_time: datetime_local_value(updated_end_time),
          status: "cancelled",
          resource_id: resource.id
        }
      )
      |> render_submit()

      assert_patch(lv, ~p"/slots/#{slot.id}")
      assert render(lv) =~ "Cancelled"
      assert Repo.get!(UserSlot, slot.id).status == :cancelled

      lv
      |> element(~s(a[href="/slots/#{slot.id}/delete"]))
      |> render_click()

      assert_patch(lv, ~p"/slots/#{slot.id}/delete")
      assert render(lv) =~ "Delete Slot"

      lv
      |> element(~s(button[phx-click="confirm_delete"]))
      |> render_click()

      assert_patch(lv, ~p"/slots")
      assert render(lv) =~ "Slot deleted."
      assert Repo.get(UserSlot, slot.id) == nil
    end
  end

  defp datetime_local_value(%DateTime{} = datetime) do
    Calendar.strftime(datetime, "%Y-%m-%dT%H:%M")
  end
end
