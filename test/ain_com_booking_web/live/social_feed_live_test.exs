defmodule AinComBookingWeb.SocialFeedLiveTest do
  use AinComBookingWeb.ConnCase, async: false

  import AinComBooking.AccountsFixtures
  import Phoenix.LiveViewTest

  alias AinComBooking.Accounts
  alias AinComBooking.Repo
  alias AinComBooking.Scheduling.BreakTime
  alias AinComBooking.Scheduling.DayOff
  alias AinComBooking.Scheduling.WorkingHour

  describe "social feed" do
    test "renders visible users and schedule summaries", %{conn: conn} do
      viewer = user_fixture(%{name: "Viewer"})
      public_user = user_fixture(%{name: "Public User", feed_visibility: :public})
      followers_user = user_fixture(%{name: "Followers User", feed_visibility: :followers})
      _private_user = user_fixture(%{name: "Private User", feed_visibility: :private})
      _link_user = user_fixture(%{name: "Link User", feed_visibility: :link})

      assert {:ok, _follow} = Accounts.follow_user(viewer, followers_user)

      insert_schedule(public_user)

      conn = log_in_user(conn, viewer)
      {:ok, _lv, html} = live(conn, ~p"/feed")

      assert html =~ "Public User"
      assert html =~ "Followers User"
      assert html =~ "Schedule Summary"
      assert html =~ "Mon:"
      assert html =~ "09:00 - 18:00"
      assert html =~ "12:00 - 13:00"
      assert html =~ "No schedule shared yet."
      refute html =~ "Private User"
      refute html =~ "Link User"
    end

    test "filters followers-only users when viewer is not following", %{conn: conn} do
      viewer = user_fixture(%{name: "Viewer"})
      _followers_user = user_fixture(%{name: "Followers User", feed_visibility: :followers})

      conn = log_in_user(conn, viewer)
      {:ok, _lv, html} = live(conn, ~p"/feed")

      refute html =~ "Followers User"
    end

    test "redirects if user is not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/feed")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log_in"
      assert %{"error" => "You must log in to access this page."} = flash
    end
  end

  defp insert_schedule(user) do
    Repo.insert!(%WorkingHour{
      user_id: user.id,
      owner_type: :user,
      weekday: :mon,
      start_time: ~T[09:00:00],
      end_time: ~T[18:00:00],
      is_day_off: false
    })

    Repo.insert!(%BreakTime{
      user_id: user.id,
      owner_type: :user,
      weekday: :mon,
      start_time: ~T[12:00:00],
      end_time: ~T[13:00:00]
    })

    Repo.insert!(%DayOff{
      user_id: user.id,
      owner_type: :user,
      date: Date.utc_today(),
      reason: "Vacation"
    })
  end
end
