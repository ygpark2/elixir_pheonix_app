defmodule AinComBookingWeb.SocialFeedLive do
  @moduledoc false
  use AinComBookingWeb, :live_view

  alias AinComBooking.Scheduling
  alias AinComBooking.Social

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-6xl space-y-6 px-4 py-6 font-outfit sm:px-6 lg:px-8">
      <section class="relative isolate overflow-hidden rounded-3xl bg-gradient-to-br from-brand-700 via-brand-600 to-gray-900 px-6 py-8 text-white shadow-theme-xl sm:px-10">
        <div class="absolute -top-20 -right-16 h-56 w-56 rounded-full bg-white/10 blur-3xl"></div>
        <div class="absolute -bottom-16 -left-14 h-40 w-40 rounded-full bg-blue-light-400/30 blur-2xl"></div>

        <div class="relative">
          <p class="inline-flex items-center rounded-full border border-white/25 bg-white/10 px-3 py-1 text-xs font-semibold tracking-wider uppercase">
            SNS Discovery
          </p>
          <h1 class="mt-4 text-2xl font-semibold sm:text-3xl">Social Feed</h1>
          <p class="mt-2 max-w-2xl text-sm text-blue-light-100 sm:text-base">
            Discover profiles and weekly schedule highlights.
          </p>

          <div class="mt-6 grid gap-3 sm:grid-cols-3">
            <div class="rounded-2xl border border-white/20 bg-white/10 px-4 py-3">
              <div class="text-xs text-blue-light-100">Visible Profiles</div>
              <div class="mt-1 text-2xl font-semibold"><%= @stats.visible_profiles %></div>
            </div>
            <div class="rounded-2xl border border-white/20 bg-white/10 px-4 py-3">
              <div class="text-xs text-blue-light-100">Shared Schedules</div>
              <div class="mt-1 text-2xl font-semibold"><%= @stats.shared_schedules %></div>
            </div>
            <div class="rounded-2xl border border-white/20 bg-white/10 px-4 py-3">
              <div class="text-xs text-blue-light-100">Day Offs This Week</div>
              <div class="mt-1 text-2xl font-semibold"><%= @stats.day_offs_this_week %></div>
            </div>
          </div>
        </div>
      </section>

      <p :if={@entries == []} class="rounded-2xl border border-dashed border-gray-300 bg-white px-6 py-10 text-center text-sm text-gray-500">
        No visible profiles in feed yet.
      </p>

      <section :if={@entries != []} class="grid gap-4 md:grid-cols-2">
        <article
          :for={entry <- @entries}
          id={"feed-user-#{entry.user.id}"}
          class="group relative overflow-hidden rounded-2xl border border-gray-200 bg-white shadow-theme-sm transition duration-200 hover:-translate-y-0.5 hover:shadow-theme-md"
        >
          <div class="absolute inset-x-0 top-0 h-1 bg-gradient-to-r from-brand-500 via-blue-light-500 to-success-500"></div>

          <div class="space-y-5 p-5">
            <div class="flex items-start justify-between gap-3">
              <div class="flex items-center gap-3">
                <div class="flex h-12 w-12 items-center justify-center rounded-xl bg-brand-50 text-base font-semibold text-brand-700 ring-1 ring-brand-100">
                  <%= initials(entry.user.name) %>
                </div>
                <div>
                  <p class="text-base font-semibold text-gray-900"><%= entry.user.name %></p>
                  <p class="text-xs text-gray-500"><%= entry.user.id %></p>
                </div>
              </div>
              <span class={["rounded-full px-2.5 py-1 text-xs font-semibold", visibility_badge_class(entry.user.feed_visibility)]}>
                <%= visibility_label(entry.user.feed_visibility) %>
              </span>
            </div>

            <div class="rounded-xl bg-gray-50 p-4 ring-1 ring-gray-100">
              <h3 class="text-sm font-semibold text-gray-800">Schedule Summary</h3>

              <p :if={!entry.summary.visible?} class="mt-3 rounded-lg border border-warning-200 bg-warning-50 px-3 py-2 text-sm text-warning-800">
                Schedule is hidden by profile visibility settings.
              </p>

              <p
                :if={entry.summary.visible? and summary_empty?(entry.summary)}
                class="mt-3 rounded-lg border border-gray-200 bg-white px-3 py-2 text-sm text-gray-600"
              >
                No schedule shared yet.
              </p>

              <div :if={entry.summary.visible? and !summary_empty?(entry.summary)} class="mt-3 grid gap-3">
                <section class="rounded-lg border border-gray-200 bg-white p-3">
                  <p class="text-xs font-semibold text-gray-500 uppercase tracking-wide">Working Hours</p>
                  <ul class="mt-2 space-y-1.5 text-sm text-gray-700">
                    <li :for={working_hour <- entry.summary.working_hours} class="flex items-center justify-between gap-3">
                      <span class="font-medium text-gray-600"><%= weekday_label(working_hour.weekday) %>:</span>
                      <span class="rounded-md bg-brand-25 px-2 py-1 text-xs text-brand-800">
                        <%= if working_hour.is_day_off do %>
                          Day off
                        <% else %>
                          <%= format_time_range(working_hour.start_time, working_hour.end_time) %>
                        <% end %>
                      </span>
                    </li>
                  </ul>
                </section>

                <section :if={entry.summary.break_times != []} class="rounded-lg border border-gray-200 bg-white p-3">
                  <p class="text-xs font-semibold text-gray-500 uppercase tracking-wide">Break Times</p>
                  <ul class="mt-2 space-y-1.5 text-sm text-gray-700">
                    <li :for={break_time <- entry.summary.break_times} class="flex items-center justify-between gap-3">
                      <span class="font-medium text-gray-600"><%= weekday_label(break_time.weekday) %>:</span>
                      <span class="rounded-md bg-orange-25 px-2 py-1 text-xs text-orange-700">
                        <%= format_time_range(break_time.start_time, break_time.end_time) %>
                      </span>
                    </li>
                  </ul>
                </section>

                <section :if={entry.summary.day_offs != []} class="rounded-lg border border-gray-200 bg-white p-3">
                  <p class="text-xs font-semibold text-gray-500 uppercase tracking-wide">Day Offs (This Week)</p>
                  <ul class="mt-2 space-y-1.5 text-sm text-gray-700">
                    <li :for={day_off <- entry.summary.day_offs} class="flex items-center justify-between gap-3">
                      <span class="font-medium"><%= day_off.date %></span>
                      <span class="rounded-md bg-error-25 px-2 py-1 text-xs text-error-700">
                        <%= if blank?(day_off.reason), do: "No reason", else: day_off.reason %>
                      </span>
                    </li>
                  </ul>
                </section>
              </div>
            </div>
          </div>
        </article>
      </section>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user
    entries = build_entries(current_user)

    {:ok,
     assign(socket,
       page_title: "Social Feed",
       entries: entries,
       stats: stats(entries)
     )}
  end

  defp build_entries(current_user) do
    current_user
    |> Social.list_feed_users()
    |> Enum.map(fn user ->
      %{user: user, summary: Scheduling.weekly_summary_for_feed(user)}
    end)
  end

  defp stats(entries) do
    %{
      visible_profiles: length(entries),
      shared_schedules: Enum.count(entries, fn entry -> entry.summary.visible? and !summary_empty?(entry.summary) end),
      day_offs_this_week: Enum.reduce(entries, 0, fn entry, acc -> acc + length(entry.summary.day_offs) end)
    }
  end

  defp summary_empty?(summary) do
    summary.working_hours == [] and summary.break_times == [] and summary.day_offs == []
  end

  defp initials(name) when is_binary(name) do
    name
    |> String.trim()
    |> String.split(~r/\s+/, trim: true)
    |> Enum.take(2)
    |> Enum.map_join(&String.first/1)
    |> String.upcase()
    |> case do
      "" -> "NA"
      value -> value
    end
  end

  defp initials(_), do: "NA"

  defp visibility_label(:public), do: "Public"
  defp visibility_label(:followers), do: "Followers"
  defp visibility_label(:link), do: "Link"
  defp visibility_label(:private), do: "Private"

  defp visibility_badge_class(:public), do: "bg-success-50 text-success-700 ring-1 ring-success-200"
  defp visibility_badge_class(:followers), do: "bg-blue-light-50 text-blue-light-700 ring-1 ring-blue-light-200"
  defp visibility_badge_class(:link), do: "bg-warning-50 text-warning-700 ring-1 ring-warning-200"
  defp visibility_badge_class(:private), do: "bg-gray-100 text-gray-700 ring-1 ring-gray-200"

  defp weekday_label(:mon), do: "Mon"
  defp weekday_label(:tue), do: "Tue"
  defp weekday_label(:wed), do: "Wed"
  defp weekday_label(:thu), do: "Thu"
  defp weekday_label(:fri), do: "Fri"
  defp weekday_label(:sat), do: "Sat"
  defp weekday_label(:sun), do: "Sun"

  defp format_time_range(start_time, end_time) do
    "#{format_time(start_time)} - #{format_time(end_time)}"
  end

  defp format_time(nil), do: "N/A"
  defp format_time(time), do: Calendar.strftime(time, "%H:%M")

  defp blank?(value), do: value in [nil, ""]
end
