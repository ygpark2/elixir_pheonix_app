defmodule AinComBookingWeb.UserProfileLiveTest do
  use AinComBookingWeb.ConnCase, async: false

  import AinComBooking.AccountsFixtures
  import Phoenix.LiveViewTest

  alias AinComBooking.Bookings.UserSlot
  alias AinComBooking.Catalog.UserResource
  alias AinComBooking.Repo
  alias AinComBooking.Social

  describe "User profile follow" do
    test "toggles follow state and reveals recent visible shares", %{conn: conn} do
      current_user = user_fixture(%{email: "current@example.com"})
      target_user = user_fixture(%{name: "Target User"})
      public_resource = insert_resource(target_user, %{name: "Public Studio"})
      followers_resource = insert_resource(target_user, %{name: "Follower Studio"})

      assert {:ok, public_post} =
               Social.create_post(target_user, %{
                 "body" => "Open consult slots",
                 "booking_note" => "Visible to anyone viewing the profile.",
                 "visibility" => "public",
                 "resource_id" => public_resource.id
               })

      assert {:ok, _followers_post} =
               Social.create_post(target_user, %{
                 "body" => "Follower priority hours",
                 "booking_note" => "Visible only after following.",
                 "visibility" => "followers",
                 "resource_id" => followers_resource.id
               })

      conn = log_in_user(conn, current_user)

      {:ok, lv, html} = live(conn, ~p"/profiles/#{target_user.id}")

      assert html =~ "Target User"
      assert html =~ "Not following"
      assert html =~ "This Month Availability"
      assert html =~ "Next 7 Days Availability"
      assert html =~ "Recent Booking Shares"
      assert html =~ "Open consult slots"
      refute html =~ "Follower priority hours"
      assert has_element?(lv, ~s(a[href="/profiles/#{target_user.id}?post_id=#{public_post.id}"]))

      html = lv |> element("#follow-toggle") |> render_click()
      assert html =~ "Following"
      assert html =~ "Unfollow"
      assert html =~ "Follower priority hours"
      assert html =~ "Open Public Page"

      html = lv |> element("#follow-toggle") |> render_click()
      assert html =~ "Not following"
      assert html =~ "Follow"
      refute html =~ "Follower priority hours"
    end

    test "opens the profile calendar modal and books the selected slot", %{conn: conn} do
      current_user = user_fixture(%{name: "Current User", email: "current@example.com"})
      target_user = user_fixture(%{name: "Target User"})
      resource = insert_resource(target_user, %{name: "Bookable Studio"})
      slot_offset = calendar_slot_offset()
      week_offset = if slot_offset == 1, do: 2, else: 1
      _week_slot = insert_slot(resource, week_offset)
      slot = insert_slot(resource, slot_offset)

      assert {:ok, post} =
               Social.create_post(target_user, %{
                 "body" => "Reserve this studio",
                 "booking_note" => "Pick a time from the profile modal.",
                 "visibility" => "public",
                 "resource_id" => resource.id
               })

      conn = log_in_user(conn, current_user)
      {:ok, lv, html} = live(conn, ~p"/profiles/#{target_user.id}")
      assert html =~ "This Month Availability"
      assert has_element?(lv, ~s(a[href="/profiles/#{target_user.id}?post_id=#{post.id}&slot_id=#{slot.id}"]))

      lv
      |> element(~s([href="/profiles/#{target_user.id}?post_id=#{post.id}&slot_id=#{slot.id}"]))
      |> render_click()

      assert_patch(lv, ~p"/profiles/#{target_user.id}?post_id=#{post.id}&slot_id=#{slot.id}")
      assert render(lv) =~ "Book From Profile"
      assert render(lv) =~ "Available Slots (Next 31 Days)"
      assert has_element?(lv, ~s(button[phx-value-slot_id="#{slot.id}"]))

      lv
      |> form("#profile-booking-form", booking: %{customer_name: "Current User", email: "current@example.com", phone: "010-0000-0000"})
      |> render_submit()

      assert render(lv) =~ "Booking confirmed."
      assert Repo.get!(UserSlot, slot.id).status == :booked
    end

    test "redirects if user is not logged in", %{conn: conn} do
      target_user = user_fixture()

      assert {:error, redirect} = live(conn, ~p"/profiles/#{target_user.id}")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log_in"
      assert %{"error" => "You must log in to access this page."} = flash
    end
  end

  defp insert_resource(user, attrs) do
    defaults = %{
      name: "Studio",
      type: "room",
      price: Decimal.new("25.00"),
      currency: "KRW",
      user_id: user.id
    }

    {:ok, resource} =
      %UserResource{}
      |> UserResource.changeset(Map.merge(defaults, attrs))
      |> Repo.insert()

    resource
  end

  defp insert_slot(resource, offset_days) do
    now = DateTime.truncate(DateTime.utc_now(), :second)
    start_time = DateTime.add(now, offset_days * 24 * 60 * 60, :second)
    end_time = DateTime.add(start_time, 30 * 60, :second)

    {:ok, slot} =
      %UserSlot{}
      |> UserSlot.changeset(%{
        start_time: start_time,
        end_time: end_time,
        status: :available,
        resource_id: resource.id
      })
      |> Repo.insert()

    slot
  end

  defp calendar_slot_offset do
    today = Date.utc_today()
    remaining_days = Date.days_in_month(today) - today.day

    if remaining_days > 7 do
      min(14, remaining_days)
    else
      1
    end
  end
end
