defmodule AinComBookingWeb.AdminDashboardLive do
  @moduledoc false
  use AinComBookingWeb, :live_view

  import Ecto.Query, warn: false

  alias AinComBooking.Accounts.Follow
  alias AinComBooking.Accounts.User
  alias AinComBooking.Repo
  alias AinComBooking.Scheduling.DayOff
  alias AinComBooking.Scheduling.WorkingHour

  def mount(_params, _session, socket) do
    stats = load_stats()
    top_profiles = load_top_profiles()
    recent_activity = load_recent_activity()

    {:ok,
     assign(socket,
       page_title: "Admin Dashboard",
       stats: stats,
       top_profiles: top_profiles,
       recent_activity: recent_activity,
       generated_at: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)
     )}
  end

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-7xl space-y-6 px-4 py-6 font-outfit sm:px-6 lg:px-8">
      <section class="relative overflow-hidden rounded-3xl bg-gradient-to-br from-gray-900 via-brand-800 to-brand-600 px-6 py-8 text-white shadow-theme-xl sm:px-10">
        <div class="absolute -right-16 -bottom-14 h-56 w-56 rounded-full bg-blue-light-300/25 blur-3xl"></div>
        <div class="absolute -left-10 -top-16 h-40 w-40 rounded-full bg-white/15 blur-2xl"></div>

        <div class="relative">
          <p class="inline-flex rounded-full border border-white/25 bg-white/10 px-3 py-1 text-xs font-semibold tracking-wider uppercase">
            Booking Platform Control
          </p>
          <h1 class="mt-4 text-2xl font-semibold sm:text-3xl">Admin Dashboard</h1>
          <p class="mt-2 max-w-2xl text-sm text-blue-light-100 sm:text-base">
            Platform Overview and operational pulse for users, schedules, and social discovery.
          </p>
          <p class="mt-4 text-xs text-blue-light-100/90">
            Generated at <%= format_datetime(@generated_at) %>
          </p>
        </div>
      </section>

      <section class="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
        <article class="rounded-2xl border border-gray-200 bg-white p-5 shadow-theme-sm">
          <p class="text-xs font-semibold uppercase tracking-wide text-gray-500">Total Users</p>
          <p class="mt-2 text-3xl font-semibold text-gray-900"><%= @stats.total_users %></p>
          <p class="mt-2 text-xs text-gray-500">New this week: <%= @stats.users_joined_this_week %></p>
        </article>

        <article class="rounded-2xl border border-gray-200 bg-white p-5 shadow-theme-sm">
          <p class="text-xs font-semibold uppercase tracking-wide text-gray-500">Total Follows</p>
          <p class="mt-2 text-3xl font-semibold text-gray-900"><%= @stats.total_follows %></p>
          <p class="mt-2 text-xs text-gray-500">New this week: <%= @stats.follows_this_week %></p>
        </article>

        <article class="rounded-2xl border border-gray-200 bg-white p-5 shadow-theme-sm">
          <p class="text-xs font-semibold uppercase tracking-wide text-gray-500">Active Schedulers</p>
          <p class="mt-2 text-3xl font-semibold text-gray-900"><%= @stats.active_schedulers %></p>
          <p class="mt-2 text-xs text-gray-500">Users with working hour templates</p>
        </article>

        <article class="rounded-2xl border border-gray-200 bg-white p-5 shadow-theme-sm">
          <p class="text-xs font-semibold uppercase tracking-wide text-gray-500">Public Profiles</p>
          <p class="mt-2 text-3xl font-semibold text-success-700"><%= @stats.public_profiles %></p>
          <p class="mt-2 text-xs text-gray-500">Followers-only: <%= @stats.followers_profiles %></p>
        </article>

        <article class="rounded-2xl border border-gray-200 bg-white p-5 shadow-theme-sm">
          <p class="text-xs font-semibold uppercase tracking-wide text-gray-500">Private Profiles</p>
          <p class="mt-2 text-3xl font-semibold text-gray-800"><%= @stats.private_profiles %></p>
          <p class="mt-2 text-xs text-gray-500">Link-only: <%= @stats.link_profiles %></p>
        </article>

        <article class="rounded-2xl border border-gray-200 bg-white p-5 shadow-theme-sm">
          <p class="text-xs font-semibold uppercase tracking-wide text-gray-500">Upcoming Day Offs</p>
          <p class="mt-2 text-3xl font-semibold text-warning-700"><%= @stats.upcoming_day_offs %></p>
          <p class="mt-2 text-xs text-gray-500">Within next 7 days</p>
        </article>
      </section>

      <section class="grid gap-4 lg:grid-cols-5">
        <article class="rounded-2xl border border-gray-200 bg-white p-5 shadow-theme-sm lg:col-span-3">
          <header class="flex items-center justify-between">
            <h2 class="text-base font-semibold text-gray-900">Top Profiles</h2>
            <span class="rounded-full bg-gray-100 px-2 py-1 text-xs font-medium text-gray-700">
              by followers
            </span>
          </header>

          <p :if={@top_profiles == []} class="mt-4 rounded-lg border border-dashed border-gray-300 px-4 py-6 text-center text-sm text-gray-500">
            No profile data yet.
          </p>

          <div :if={@top_profiles != []} class="mt-4 overflow-x-auto">
            <table class="min-w-full divide-y divide-gray-200 text-sm">
              <thead>
                <tr class="text-left text-xs uppercase tracking-wide text-gray-500">
                  <th class="pb-2">Profile</th>
                  <th class="pb-2">Visibility</th>
                  <th class="pb-2 text-right">Followers</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100">
                <tr :for={profile <- @top_profiles} class="text-gray-700">
                  <td class="py-2">
                    <p class="font-medium text-gray-900"><%= profile.name %></p>
                    <p class="text-xs text-gray-500"><%= profile.id %></p>
                  </td>
                  <td class="py-2">
                    <span class={["rounded-full px-2 py-1 text-xs font-medium", visibility_badge_class(profile.feed_visibility)]}>
                      <%= visibility_label(profile.feed_visibility) %>
                    </span>
                  </td>
                  <td class="py-2 text-right font-semibold text-gray-900"><%= profile.followers %></td>
                </tr>
              </tbody>
            </table>
          </div>
        </article>

        <article class="rounded-2xl border border-gray-200 bg-white p-5 shadow-theme-sm lg:col-span-2">
          <h2 class="text-base font-semibold text-gray-900">Visibility Distribution</h2>

          <div class="mt-4 space-y-3">
            <div :for={item <- visibility_distribution(@stats)} class="space-y-1">
              <div class="flex items-center justify-between text-xs text-gray-600">
                <span><%= item.label %></span>
                <span><%= item.count %></span>
              </div>
              <div class="h-2 rounded-full bg-gray-100">
                <div class={["h-2 rounded-full", item.color]} style={"width: #{item.percent}%"}></div>
              </div>
            </div>
          </div>
        </article>
      </section>

      <section class="rounded-2xl border border-gray-200 bg-white p-5 shadow-theme-sm">
        <h2 class="text-base font-semibold text-gray-900">Recent Activity</h2>

        <p :if={@recent_activity == []} class="mt-4 text-sm text-gray-500">No recent activity.</p>

        <ul :if={@recent_activity != []} class="mt-4 space-y-3">
          <li :for={event <- @recent_activity} class="flex items-start gap-3">
            <span class={["mt-1 inline-flex h-2.5 w-2.5 rounded-full", activity_dot_class(event.type)]}></span>
            <div>
              <p class="text-sm text-gray-800"><%= event.message %></p>
              <p class="text-xs text-gray-500"><%= format_datetime(event.inserted_at) %></p>
            </div>
          </li>
        </ul>
      </section>
    </div>
    """
  end

  defp load_stats do
    total_users = Repo.aggregate(User, :count, :id)
    total_follows = Repo.aggregate(Follow, :count, :id)

    public_profiles = Repo.aggregate(from(u in User, where: u.feed_visibility == :public), :count, :id)
    followers_profiles = Repo.aggregate(from(u in User, where: u.feed_visibility == :followers), :count, :id)
    private_profiles = Repo.aggregate(from(u in User, where: u.feed_visibility == :private), :count, :id)
    link_profiles = Repo.aggregate(from(u in User, where: u.feed_visibility == :link), :count, :id)

    active_schedulers =
      Repo.one(
        from(w in WorkingHour,
          where: w.owner_type == :user,
          select: count(fragment("DISTINCT ?", w.user_id))
        )
      ) || 0

    today = Date.utc_today()
    week_end = Date.add(today, 6)
    week_start = Date.beginning_of_week(today)
    week_start_naive = NaiveDateTime.new!(week_start, ~T[00:00:00])

    upcoming_day_offs =
      Repo.aggregate(
        from(d in DayOff,
          where: d.owner_type == :user and d.date >= ^today and d.date <= ^week_end
        ),
        :count,
        :id
      )

    users_joined_this_week =
      Repo.aggregate(from(u in User, where: u.inserted_at >= ^week_start_naive), :count, :id)

    follows_this_week =
      Repo.aggregate(from(f in Follow, where: f.inserted_at >= ^week_start_naive), :count, :id)

    %{
      total_users: total_users,
      total_follows: total_follows,
      public_profiles: public_profiles,
      followers_profiles: followers_profiles,
      private_profiles: private_profiles,
      link_profiles: link_profiles,
      active_schedulers: active_schedulers,
      upcoming_day_offs: upcoming_day_offs,
      users_joined_this_week: users_joined_this_week,
      follows_this_week: follows_this_week
    }
  end

  defp load_top_profiles do
    Repo.all(
      from(u in User,
        left_join: f in Follow,
        on: f.followed_id == u.id,
        group_by: [u.id, u.name, u.feed_visibility, u.inserted_at],
        order_by: [desc: count(f.id), desc: u.inserted_at],
        limit: 5,
        select: %{
          id: u.id,
          name: u.name,
          feed_visibility: u.feed_visibility,
          followers: count(f.id)
        }
      )
    )
  end

  defp load_recent_activity do
    user_events =
      Repo.all(
        from(u in User,
          order_by: [desc: u.inserted_at],
          limit: 5,
          select: %{type: :user, inserted_at: u.inserted_at, message: fragment("('New user: ' || ?)", u.name)}
        )
      )

    follow_events =
      Repo.all(
        from(f in Follow,
          join: u in User,
          on: u.id == f.followed_id,
          order_by: [desc: f.inserted_at],
          limit: 5,
          select: %{type: :follow, inserted_at: f.inserted_at, message: fragment("(? || ' received a new follower')", u.name)}
        )
      )

    (user_events ++ follow_events)
    |> Enum.sort_by(& &1.inserted_at, {:desc, NaiveDateTime})
    |> Enum.take(8)
  end

  defp visibility_distribution(stats) do
    total = max(stats.total_users, 1)

    [
      %{label: "Public", count: stats.public_profiles, percent: percent(stats.public_profiles, total), color: "bg-success-500"},
      %{label: "Followers", count: stats.followers_profiles, percent: percent(stats.followers_profiles, total), color: "bg-blue-light-500"},
      %{label: "Private", count: stats.private_profiles, percent: percent(stats.private_profiles, total), color: "bg-gray-600"},
      %{label: "Link", count: stats.link_profiles, percent: percent(stats.link_profiles, total), color: "bg-warning-500"}
    ]
  end

  defp percent(value, total) when total > 0 do
    value
    |> Kernel./(total)
    |> Kernel.*(100)
    |> Float.round(1)
  end

  defp visibility_label(:public), do: "Public"
  defp visibility_label(:followers), do: "Followers"
  defp visibility_label(:private), do: "Private"
  defp visibility_label(:link), do: "Link"

  defp visibility_badge_class(:public), do: "bg-success-50 text-success-700 ring-1 ring-success-200"
  defp visibility_badge_class(:followers), do: "bg-blue-light-50 text-blue-light-700 ring-1 ring-blue-light-200"
  defp visibility_badge_class(:private), do: "bg-gray-100 text-gray-700 ring-1 ring-gray-200"
  defp visibility_badge_class(:link), do: "bg-warning-50 text-warning-700 ring-1 ring-warning-200"

  defp activity_dot_class(:user), do: "bg-brand-500"
  defp activity_dot_class(:follow), do: "bg-success-500"

  defp format_datetime(%NaiveDateTime{} = value), do: Calendar.strftime(value, "%Y-%m-%d %H:%M")
end
