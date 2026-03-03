defmodule AinComBookingWeb.SocialFeedLiveTest do
  use AinComBookingWeb.ConnCase, async: false

  import AinComBooking.AccountsFixtures
  import Phoenix.LiveViewTest

  alias AinComBooking.Accounts
  alias AinComBooking.Bookings.UserSlot
  alias AinComBooking.Catalog.UserResource
  alias AinComBooking.Repo
  alias AinComBooking.Social

  describe "social feed" do
    test "renders bookable posts and allows booking from the weekly modal", %{conn: conn} do
      viewer = user_fixture(%{name: "Viewer", email: "viewer@example.com"})
      author = user_fixture(%{name: "Public User"})
      resource = insert_resource(author, %{name: "Weekly AMA"})
      slot = insert_slot(resource)

      assert {:ok, post} =
               Social.create_post(author, %{
                 "body" => "Ask me anything this week",
                 "booking_note" => "Reserve a slot and I will send the details.",
                 "visibility" => "public",
                 "resource_id" => resource.id
               })

      conn = log_in_user(conn, viewer)
      {:ok, lv, html} = live(conn, ~p"/feed")

      assert html =~ "Social Availability Feed"
      assert html =~ "Ask me anything this week"
      assert html =~ viewer.email
      assert html =~ "/share/#{post.id}"
      assert html =~ "feed-user-menu-style"
      assert html =~ "feed-account-menu"
      assert html =~ "Services"
      assert html =~ "Resources"
      assert html =~ ">Post<"
      refute html =~ "What availability do you want to share?"

      lv
      |> element(~s(button[phx-click="open_post_modal"]))
      |> render_click()

      rendered = render(lv)
      assert rendered =~ "Share Availability"
      assert rendered =~ "What availability do you want to share?"

      lv
      |> element(~s([href="/feed/posts/#{post.id}"]))
      |> render_click()

      assert_patch(lv, ~p"/feed/posts/#{post.id}")
      rendered = render(lv)
      assert rendered =~ "Book From Share"
      assert rendered =~ "Weekly AMA"

      lv
      |> element(~s(button[phx-value-slot_id="#{slot.id}"]))
      |> render_click()

      lv
      |> form("#booking-form", booking: %{customer_name: "Viewer", email: "viewer@example.com", phone: "010-0000-0000"})
      |> render_submit()

      assert render(lv) =~ "Booking confirmed."
      assert Repo.get!(UserSlot, slot.id).status == :booked

      lv
      |> element(~s([href="/feed?scope=bookings"]))
      |> render_click()

      assert_patch(lv, ~p"/feed?scope=bookings")
      assert render(lv) =~ "Booked from shared availability"
      assert render(lv) =~ "Weekly AMA"
    end

    test "shows follower-only shares only after following", %{conn: conn} do
      viewer = user_fixture(%{name: "Viewer"})
      author = user_fixture(%{name: "Followers User"})
      resource = insert_resource(author, %{name: "Follower Office Hour"})

      assert {:ok, _post} =
               Social.create_post(author, %{
                 "body" => "For followers only",
                 "booking_note" => "Follow me to book",
                 "visibility" => "followers",
                 "resource_id" => resource.id
               })

      conn = log_in_user(conn, viewer)
      {:ok, _lv, html} = live(conn, ~p"/feed")

      refute html =~ "For followers only"

      assert {:ok, _follow} = Accounts.follow_user(viewer, author)

      {:ok, _lv, html} = live(conn, ~p"/feed")
      assert html =~ "For followers only"
    end

    test "follows a suggested account from the feed UI and refreshes the following tab", %{conn: conn} do
      viewer = user_fixture(%{name: "Viewer"})
      author = user_fixture(%{name: "Suggested User"})
      resource = insert_resource(author, %{name: "Follower Sprint"})

      assert {:ok, _post} =
               Social.create_post(author, %{
                 "body" => "Book this only if you follow me",
                 "booking_note" => "Followers get priority",
                 "visibility" => "followers",
                 "resource_id" => resource.id
               })

      conn = log_in_user(conn, viewer)
      {:ok, lv, html} = live(conn, ~p"/feed?scope=following")

      refute html =~ "Book this only if you follow me"
      assert html =~ "Suggested Accounts"
      assert has_element?(lv, ~s(a[href="/profiles/#{author.id}"]))

      lv
      |> element("#toggle-follow-#{author.id}")
      |> render_click()

      rendered = render(lv)
      assert rendered =~ "Book this only if you follow me"
      assert rendered =~ "Following"
      assert Accounts.following?(viewer, author)
    end

    test "shows the admin dashboard link only for admin users", %{conn: conn} do
      admin_user = user_fixture(%{name: "Admin Viewer", role: :admin})
      member_user = user_fixture(%{name: "Member Viewer"})

      admin_conn = log_in_user(conn, admin_user)
      {:ok, admin_lv, admin_html} = live(admin_conn, ~p"/feed")

      assert admin_html =~ "Admin Access"
      assert has_element?(admin_lv, ~s(a[href="/admin"]))

      member_conn = log_in_user(conn, member_user)
      {:ok, _member_lv, member_html} = live(member_conn, ~p"/feed")

      refute member_html =~ "Admin Access"
    end

    test "filters to my shares when scope is mine", %{conn: conn} do
      viewer = user_fixture(%{name: "Viewer"})
      author = user_fixture(%{name: "Author"})
      viewer_resource = insert_resource(viewer, %{name: "Viewer Desk"})
      author_resource = insert_resource(author, %{name: "Author Desk"})

      assert {:ok, _post} =
               Social.create_post(viewer, %{
                 "body" => "My open desk hours",
                 "booking_note" => "Viewer-owned availability",
                 "visibility" => "public",
                 "resource_id" => viewer_resource.id
               })

      assert {:ok, _post} =
               Social.create_post(author, %{
                 "body" => "Author open desk hours",
                 "booking_note" => "Author-owned availability",
                 "visibility" => "public",
                 "resource_id" => author_resource.id
               })

      conn = log_in_user(conn, viewer)
      {:ok, _lv, html} = live(conn, ~p"/feed?scope=mine")

      assert html =~ "My open desk hours"
      refute html =~ "Author open desk hours"
    end

    test "redirects if user is not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/feed")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log_in"
      assert %{"error" => "You must log in to access this page."} = flash
    end

    test "public share page is accessible without login and can book", %{conn: conn} do
      author = user_fixture(%{name: "Public User"})
      resource = insert_resource(author, %{name: "Public Room"})
      slot = insert_slot(resource)

      assert {:ok, post} =
               Social.create_post(author, %{
                 "body" => "Book my public room",
                 "booking_note" => "Pick a free slot below.",
                 "visibility" => "public",
                 "resource_id" => resource.id
               })

      {:ok, lv, html} = live(conn, ~p"/share/#{post.id}")

      assert html =~ "Public Booking Share"
      assert html =~ "Book my public room"

      lv
      |> element(~s(button[phx-value-slot_id="#{slot.id}"]))
      |> render_click()

      lv
      |> form("#public-booking-form", booking: %{customer_name: "Guest", email: "guest@example.com", phone: "010-0000-0000"})
      |> render_submit()

      assert render(lv) =~ "Booking confirmed."
      assert Repo.get!(UserSlot, slot.id).status == :booked
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

  defp insert_slot(resource) do
    now = DateTime.truncate(DateTime.utc_now(), :second)
    start_time = DateTime.add(now, 24 * 60 * 60, :second)
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
end
