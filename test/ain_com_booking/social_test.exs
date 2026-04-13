defmodule AinComBooking.SocialTest do
  use AinComBooking.DataCase, async: false

  import AinComBooking.AccountsFixtures

  alias AinComBooking.Accounts
  alias AinComBooking.Bookings.UserSlot
  alias AinComBooking.Catalog
  alias AinComBooking.Catalog.UserResource
  alias AinComBooking.Repo
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

  describe "feed posts" do
    test "returns public posts, followed followers-only posts, and own private posts" do
      viewer = user_fixture(%{name: "Viewer"})
      author = user_fixture(%{name: "Author"})
      follower_only_author = user_fixture(%{name: "Follower Only"})
      private_author = user_fixture(%{name: "Private Author"})

      resource = insert_resource(author, %{name: "Office Hour"})
      followers_resource = insert_resource(follower_only_author, %{name: "Follower Session"})
      private_resource = insert_resource(private_author, %{name: "Private Session"})
      viewer_resource = insert_resource(viewer, %{name: "My Session"})

      assert {:ok, public_post} =
               Social.create_post(author, %{
                 "body" => "Public booking",
                 "booking_note" => "Open to everyone",
                 "visibility" => "public",
                 "resource_id" => resource.id
               })

      assert {:ok, followers_post} =
               Social.create_post(follower_only_author, %{
                 "body" => "Followers booking",
                 "booking_note" => "Followers only",
                 "visibility" => "followers",
                 "resource_id" => followers_resource.id
               })

      assert {:ok, _private_post} =
               Social.create_post(private_author, %{
                 "body" => "Private booking",
                 "booking_note" => "Private",
                 "visibility" => "private",
                 "resource_id" => private_resource.id
               })

      assert {:ok, own_private_post} =
               Social.create_post(viewer, %{
                 "body" => "My private booking",
                 "booking_note" => "Just for me",
                 "visibility" => "private",
                 "resource_id" => viewer_resource.id
               })

      assert {:ok, _follow} = Accounts.follow_user(viewer, follower_only_author)

      posts = Social.list_feed_posts(viewer)
      ids = Enum.map(posts, & &1.id)

      assert public_post.id in ids
      assert followers_post.id in ids
      assert own_private_post.id in ids
      refute Enum.any?(posts, &(&1.body == "Private booking"))
    end

    test "lists weekly slots for a shared post and books from the post" do
      viewer = user_fixture(%{name: "Viewer", email: "viewer@example.com"})
      author = user_fixture(%{name: "Author"})
      resource = insert_resource(author, %{name: "Consulting", price: Decimal.new("35.00")})
      slot = insert_slot(resource)

      assert {:ok, post} =
               Social.create_post(author, %{
                 "body" => "Consulting this week",
                 "booking_note" => "Reserve a 30 minute session",
                 "visibility" => "public",
                 "resource_id" => resource.id
               })

      slots = Social.list_weekly_slots_for_post(post)
      assert Enum.any?(slots, &(&1.id == slot.id))

      assert {:ok, booking} =
               Social.create_booking_from_post(post, %{
                 "slot_id" => slot.id,
                 "customer_name" => viewer.name,
                 "email" => viewer.email,
                 "phone" => "010-0000-0000"
               })

      assert booking.slot_id == slot.id
      assert Repo.get!(UserSlot, slot.id).status == :booked
      refute Enum.any?(Social.list_weekly_slots_for_post(post), &(&1.id == slot.id))
    end

    test "supports service-based shares owned directly by the user" do
      author = user_fixture(%{name: "Service Author"})

      {:ok, service} =
        Catalog.create_user_service(author, %{
          "name" => "Strategy Session",
          "description_text" => "A deep-dive call",
          "duration" => 60,
          "price" => "120.00",
          "currency" => "USD",
          "is_active" => true,
          "is_public" => true
        })

      slot = insert_service_slot(service)

      assert {:ok, post} =
               Social.create_post(author, %{
                 "body" => "Strategy session this week",
                 "booking_note" => "Use one of the open windows below",
                 "visibility" => "public",
                 "service_id" => service.id
               })

      targets = Social.list_share_targets(author)
      assert Enum.any?(targets.services, &(&1.id == service.id and &1.slot_count == 1))
      assert Enum.any?(Social.list_weekly_slots_for_post(post), &(&1.id == slot.id))
    end

    test "auto-generates weekly slots for a share without pre-created slot rows" do
      viewer = user_fixture(%{name: "Viewer", email: "viewer@example.com"})
      author = user_fixture(%{name: "Author"})
      resource = insert_resource(author, %{name: "Auto Room", price: Decimal.new("40.00")})
      tomorrow = Date.add(local_date("Asia/Seoul"), 1)

      assert {:ok, post} =
               Social.create_post(author, %{
                 "body" => "Auto availability",
                 "booking_note" => "Calculated from recurring rules",
                 "visibility" => "public",
                 "resource_id" => resource.id,
                 "auto_slots_enabled" => "true",
                 "schedule_start_date" => tomorrow,
                 "schedule_end_date" => tomorrow,
                 "work_start_time" => ~T[09:00:00],
                 "work_end_time" => ~T[12:00:00],
                 "slot_minutes" => "60",
                 "break_minutes" => "10",
                 "available_weekdays" => weekday_name(tomorrow),
                 "excluded_dates" => "",
                 "default_max_bookings" => "2",
                 "timezone" => "Asia/Seoul"
               })

      slots = Social.list_weekly_slots_for_post(post)
      assert length(slots) == 2
      first_slot = hd(slots)
      assert first_slot.remaining_capacity == 2

      assert {:ok, _booking} =
               Social.create_booking_from_post(post, %{
                 "slot_id" => first_slot.id,
                 "customer_name" => viewer.name,
                 "email" => viewer.email,
                 "phone" => "010-0000-1111"
               })

      refreshed_slots = Social.list_weekly_slots_for_post(post)
      assert Enum.any?(refreshed_slots, &(&1.start_time == first_slot.start_time and &1.remaining_capacity == 1))
    end
  end

  defp insert_resource(user, attrs) do
    defaults = %{
      name: "Consultation Room",
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

  defp insert_service_slot(service) do
    now = DateTime.truncate(DateTime.utc_now(), :second)
    start_time = DateTime.add(now, 24 * 60 * 60, :second)
    end_time = DateTime.add(start_time, 60 * 60, :second)

    {:ok, slot} =
      %UserSlot{}
      |> UserSlot.changeset(%{
        start_time: start_time,
        end_time: end_time,
        status: :available,
        service_id: service.id
      })
      |> Repo.insert()

    slot
  end

  defp weekday_name(date) do
    case Date.day_of_week(date) do
      1 -> "mon"
      2 -> "tue"
      3 -> "wed"
      4 -> "thu"
      5 -> "fri"
      6 -> "sat"
      7 -> "sun"
    end
  end

  defp local_date(timezone) do
    offset_seconds =
      case timezone do
        "Asia/Seoul" -> 9 * 60 * 60
        _ -> 0
      end

    DateTime.utc_now()
    |> DateTime.add(offset_seconds, :second)
    |> DateTime.to_date()
  end
end
