defmodule AinComBookingWeb.UserProfileLive do
  @moduledoc false
  use AinComBookingWeb, :live_view

  alias AinComBooking.Accounts
  alias AinComBooking.Social
  alias Phoenix.LiveView.JS

  @profile_window_days 31

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-[#f7f9f9] px-4 py-6 font-outfit text-slate-900 sm:px-6">
      <div class="mx-auto max-w-4xl space-y-6">
        <section class="overflow-hidden rounded-3xl border border-slate-200 bg-white shadow-sm">
          <div class="border-b border-slate-200 bg-slate-50 px-6 py-5">
            <p class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-400">User Profile</p>
            <h1 class="mt-2 text-2xl font-semibold tracking-tight text-slate-950"><%= @user.name %></h1>
            <p class="mt-1 text-xs text-slate-500"><%= @user.id %></p>
          </div>

          <div class="grid gap-6 px-6 py-6 md:grid-cols-[minmax(0,1fr)_220px]">
            <div>
              <div class="text-sm font-semibold text-slate-900"><%= if @following, do: "Following", else: "Not following" %></div>
              <p :if={@following} class="mt-3 text-sm leading-6 text-slate-600">
                Follower-only booking shares from this profile are visible in your feed and below in the profile preview.
              </p>
              <p :if={!@following} class="mt-3 text-sm leading-6 text-slate-600">
                Follow this profile to unlock follower-only booking shares in the feed and on this page.
              </p>
            </div>

            <div :if={@show_follow_action} class="flex items-start md:justify-end">
              <.button id="follow-toggle" phx-click="toggle_follow" phx-disable-with="Updating..." class="rounded-full px-5">
                <%= if @following, do: "Unfollow", else: "Follow" %>
              </.button>
            </div>
          </div>
        </section>

        <section class="rounded-3xl border border-slate-200 bg-white p-6 shadow-sm">
          <div class="flex items-center justify-between gap-3">
            <div>
              <h2 class="text-lg font-semibold tracking-tight text-slate-950">This Month Availability</h2>
              <p class="mt-1 text-sm text-slate-500">Calendar view for visible slots in <%= @monthly_calendar.label %>.</p>
            </div>
            <span class="rounded-full bg-brand-25 px-3 py-1 text-xs font-semibold text-brand-700">
              <%= @monthly_calendar.total_slots %> open
            </span>
          </div>

          <div class="mt-6 grid grid-cols-7 gap-2">
            <div
              :for={label <- @monthly_calendar.day_headers}
              class="px-2 text-center text-[11px] font-semibold uppercase tracking-[0.18em] text-slate-400"
            >
              <%= label %>
            </div>
          </div>

          <div class="mt-3 space-y-2">
            <div :for={week <- @monthly_calendar.weeks} class="grid grid-cols-7 gap-2">
              <div
                :for={day <- week}
                class={[
                  "min-h-28 rounded-2xl border px-2.5 py-2",
                  day.outside_month && "border-transparent bg-transparent",
                  !day.outside_month && day.is_today && "border-brand-200 bg-brand-25",
                  !day.outside_month && !day.is_today && "border-slate-200 bg-slate-50"
                ]}
              >
                <div :if={!day.outside_month} class="flex items-center justify-between gap-2">
                  <span class={[
                    "text-sm font-semibold",
                    day.is_past && "text-slate-400",
                    !day.is_past && "text-slate-900"
                  ]}>
                    <%= day.day_number %>
                  </span>
                  <span class="rounded-full bg-white px-2 py-0.5 text-[11px] font-semibold text-slate-500 ring-1 ring-slate-200">
                    <%= day.slot_count %>
                  </span>
                </div>

                <p :if={!day.outside_month && day.slots == [] && !day.is_past} class="mt-3 text-[11px] text-slate-400">
                  No slots
                </p>

                <p :if={!day.outside_month && day.is_past} class="mt-3 text-[11px] text-slate-300">
                  Past
                </p>

                <div :if={!day.outside_month && day.slots != []} class="mt-3 space-y-1.5">
                <.link
                  :for={slot <- Enum.take(day.slots, 2)}
                  patch={profile_slot_path(@user.id, slot.post_id, slot.id)}
                  class="block rounded-xl border border-slate-200 bg-white px-2 py-1.5 text-[11px] font-semibold text-slate-700 transition hover:border-brand-200 hover:bg-brand-25"
                >
                  <span class="block text-slate-900"><%= calendar_time_range(slot) %></span>
                  <span class="mt-0.5 block truncate text-slate-400"><%= slot_line_item(slot) %> · <%= slot_capacity(slot) %></span>
                </.link>

                  <p :if={day.slot_count > 2} class="text-[11px] font-medium text-slate-400">
                    + <%= day.slot_count - 2 %> more
                  </p>
                </div>
              </div>
            </div>
          </div>
        </section>

        <section class="rounded-3xl border border-slate-200 bg-white p-6 shadow-sm">
          <div class="flex items-center justify-between gap-3">
            <div>
              <h2 class="text-lg font-semibold tracking-tight text-slate-950">Next 7 Days Availability</h2>
              <p class="mt-1 text-sm text-slate-500">All visible slots across this profile, grouped by day.</p>
            </div>
            <span class="rounded-full bg-emerald-50 px-3 py-1 text-xs font-semibold text-emerald-700">
              <%= calendar_total_slots(@weekly_calendar_days) %> open
            </span>
          </div>

          <div class="mt-6 grid gap-4 md:grid-cols-2 xl:grid-cols-7">
            <div
              :for={day <- @weekly_calendar_days}
              class="rounded-2xl border border-slate-200 bg-slate-50 px-3 py-3"
            >
              <div class="flex items-center justify-between gap-2">
                <div>
                  <p class="text-[11px] font-semibold uppercase tracking-[0.16em] text-slate-400"><%= day.label %></p>
                  <p class="mt-1 text-sm font-semibold text-slate-900"><%= day.month_day %></p>
                </div>
                <span class="rounded-full bg-white px-2 py-1 text-[11px] font-semibold text-slate-600 ring-1 ring-slate-200">
                  <%= day.slot_count %>
                </span>
              </div>

              <p :if={day.slots == []} class="mt-4 text-xs leading-5 text-slate-400">
                No visible slots
              </p>

              <div :if={day.slots != []} class="mt-4 space-y-2">
                <.link
                  :for={slot <- Enum.take(day.slots, 3)}
                  patch={profile_slot_path(@user.id, slot.post_id, slot.id)}
                  class="block rounded-xl border border-slate-200 bg-white px-2.5 py-2 transition hover:border-brand-200 hover:bg-brand-25"
                >
                  <div class="text-xs font-semibold text-slate-900"><%= calendar_time_range(slot) %></div>
                  <div class="mt-1 truncate text-[11px] text-slate-500"><%= slot_line_item(slot) %> · <%= slot_capacity(slot) %></div>
                </.link>

                <p :if={day.slot_count > 3} class="text-[11px] font-medium text-slate-400">
                  + <%= day.slot_count - 3 %> more
                </p>
              </div>
            </div>
          </div>
        </section>

        <section class="rounded-3xl border border-slate-200 bg-white p-6 shadow-sm">
          <div class="flex items-center justify-between gap-3">
            <div>
              <h2 class="text-lg font-semibold tracking-tight text-slate-950">Recent Booking Shares</h2>
              <p class="mt-1 text-sm text-slate-500">Only posts visible to you are shown here.</p>
            </div>
            <span class="rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold text-slate-600">
              <%= length(@profile_entries) %> visible
            </span>
          </div>

          <p :if={@profile_entries == []} class="mt-6 rounded-2xl border border-dashed border-slate-300 bg-slate-50 px-4 py-6 text-sm text-slate-500">
            No visible booking shares from this profile yet.
          </p>

          <div :if={@profile_entries != []} class="mt-6 space-y-4">
            <article
              :for={entry <- @profile_entries}
              id={"profile-post-#{entry.post.id}"}
              class="rounded-2xl border border-slate-200 bg-slate-50 px-4 py-4"
            >
              <div class="flex flex-wrap items-center gap-2">
                <span class="text-sm font-semibold text-slate-900"><%= visibility_label(entry.post.visibility) %></span>
                <span class="text-sm text-slate-400">·</span>
                <span class="text-sm text-slate-400"><%= relative_posted_at(entry.post.inserted_at) %></span>
                <span class="ml-auto rounded-full bg-emerald-50 px-2.5 py-1 text-[11px] font-semibold text-emerald-700">
                  <%= entry.slot_count %> open
                </span>
              </div>

              <p class="mt-3 whitespace-pre-line text-sm leading-6 text-slate-800"><%= entry.post.body %></p>
              <p class="mt-2 text-sm leading-6 text-slate-600"><%= entry.post.booking_note %></p>

              <div class="mt-3 text-xs font-semibold uppercase tracking-[0.18em] text-slate-400">
                <%= target_summary(entry.post) %>
              </div>

              <div class="mt-4 flex flex-wrap items-center gap-2">
                <.link
                  patch={profile_post_path(@user.id, entry.post.id)}
                  class="inline-flex items-center gap-2 rounded-full bg-slate-900 px-3 py-2 text-xs font-semibold text-white transition hover:bg-slate-800"
                >
                  <.icon name="hero-calendar-days" class="h-4 w-4" />
                  View Availability
                </.link>

                <.link
                  :if={entry.post.visibility == :public}
                  navigate={share_path(entry.post.id)}
                  class="inline-flex items-center gap-2 rounded-full border border-slate-200 bg-white px-3 py-2 text-xs font-semibold text-slate-700 transition hover:bg-slate-100"
                >
                  <.icon name="hero-arrow-top-right-on-square" class="h-4 w-4" />
                  Open Public Page
                </.link>
              </div>
            </article>
          </div>
        </section>
      </div>

      <.modal
        :if={@selected_entry}
        id="profile-booking-modal"
        show={true}
        on_cancel={JS.patch(profile_path(@user.id))}
      >
        <div class="space-y-0">
          <div class="border-b border-slate-200 px-1 pb-4">
            <p class="text-xs font-semibold uppercase tracking-[0.18em] text-slate-400">Book From Profile</p>
            <h2 class="mt-2 pr-8 text-2xl font-semibold tracking-tight text-slate-950"><%= @selected_entry.post.body %></h2>
            <p class="mt-2 text-sm leading-6 text-slate-600"><%= @selected_entry.post.booking_note %></p>
            <div class="mt-3 text-xs font-semibold uppercase tracking-[0.18em] text-slate-400"><%= target_summary(@selected_entry.post) %></div>

            <div
              :if={@selected_entry.post.visibility == :public}
              class="mt-3 break-all rounded-2xl bg-slate-50 px-4 py-3 text-sm text-brand-700 ring-1 ring-slate-200"
            >
              <%= share_path(@selected_entry.post.id) %>
            </div>

            <p :if={@selected_entry.post.visibility != :public} class="mt-3 rounded-2xl bg-slate-50 px-4 py-3 text-sm text-slate-500 ring-1 ring-slate-200">
              This share is visible from authenticated profile and feed views only.
            </p>
          </div>

          <div class="grid gap-0 pt-4 lg:grid-cols-[minmax(0,1.18fr)_minmax(0,0.82fr)]">
            <div class="space-y-3 pr-0 lg:pr-5">
              <div class="flex items-center justify-between gap-3">
                <h3 class="text-sm font-semibold uppercase tracking-[0.18em] text-slate-400">Available Slots (Next 31 Days)</h3>
                <div class="flex items-center gap-2">
                  <span class="rounded-full bg-slate-100 px-2.5 py-1 text-[11px] font-semibold uppercase tracking-[0.16em] text-slate-500">
                    <%= Social.post_timezone(@selected_entry.post) %>
                  </span>
                  <span class="rounded-full bg-emerald-50 px-2.5 py-1 text-xs font-semibold text-emerald-700">
                    <%= @selected_entry.slot_count %> open
                  </span>
                </div>
              </div>

              <p :if={@selected_entry.bookable_slots == []} class="rounded-2xl border border-dashed border-slate-300 bg-slate-50 px-4 py-6 text-sm text-slate-500">
                No open slots remain for the current booking window.
              </p>

              <div :if={@selected_entry.bookable_slots != []} class="space-y-2">
                <button
                  :for={slot <- @selected_entry.bookable_slots}
                  type="button"
                  phx-click="select_slot"
                  phx-value-slot_id={slot.id}
                  class={[
                    "w-full rounded-2xl border px-4 py-3 text-left transition",
                    @selected_slot_id == slot.id &&
                      "border-brand-400 bg-brand-25 ring-2 ring-brand-100",
                    @selected_slot_id != slot.id &&
                      "border-slate-200 bg-white hover:border-slate-300 hover:bg-slate-50"
                  ]}
                >
                  <div class="flex flex-wrap items-center justify-between gap-3">
                    <div>
                      <div class="text-sm font-semibold text-slate-950"><%= format_slot_datetime(@selected_entry.post, slot.start_time, slot.end_time) %></div>
                      <div class="mt-1 text-xs text-slate-500"><%= slot_line_item(slot) %> · <%= slot_capacity(slot) %></div>
                    </div>
                    <div class="text-xs font-semibold text-brand-700"><%= slot_price(slot) %></div>
                  </div>
                </button>
              </div>
            </div>

            <div class="mt-5 border-t border-slate-200 pt-5 lg:mt-0 lg:border-t-0 lg:border-l lg:border-slate-200 lg:pl-5 lg:pt-0">
              <div class="rounded-3xl bg-slate-50 p-5 ring-1 ring-slate-200">
                <div>
                  <h3 class="text-sm font-semibold uppercase tracking-[0.18em] text-slate-400">Reserve Selected Slot</h3>
                  <p :if={!@selected_slot_id} class="mt-2 text-sm text-slate-500">Choose a slot from the left to book it.</p>
                  <p :if={@selected_slot_id} class="mt-2 text-sm leading-6 text-slate-600"><%= selected_slot_summary(@selected_entry.post, @selected_entry.bookable_slots, @selected_slot_id) %></p>
                </div>

                <.simple_form
                  for={@booking_form}
                  as={:booking}
                  id="profile-booking-form"
                  phx-submit="book_slot"
                >
                  <.input field={@booking_form[:customer_name]} type="text" label="Name" />
                  <.input field={@booking_form[:email]} type="email" label="Email" />
                  <.input field={@booking_form[:phone]} type="text" label="Phone" />
                  <:actions>
                    <.button type="submit" disabled={is_nil(@selected_slot_id)} phx-disable-with="Booking..." class="w-full rounded-full bg-brand-600 hover:bg-brand-500">
                      Book This Time
                    </.button>
                  </:actions>
                </.simple_form>
              </div>
            </div>
          </div>
        </div>
      </.modal>
    </div>
    """
  end

  def mount(%{"id" => user_id}, _session, socket) do
    user = Accounts.get_user!(user_id)
    current_user = socket.assigns.current_user

    following = Accounts.following?(current_user, user)

    {:ok,
     socket
     |> assign(
       user: user,
       following: following,
       show_follow_action: current_user.id != user.id,
       selected_entry: nil,
       selected_slot_id: nil,
       booking_form: booking_form(current_user)
     )
     |> load_profile_entries()}
  end

  def handle_params(params, _uri, socket) do
    case Map.get(params, "post_id") do
      nil ->
        {:noreply, clear_modal(socket)}

      post_id ->
        requested_slot_id = Map.get(params, "slot_id")

        case find_entry(socket.assigns.profile_entries, post_id) do
          nil ->
            {:noreply,
             socket
             |> put_flash(:error, "That booking share is not visible on this profile.")
             |> push_patch(to: profile_path(socket.assigns.user.id))}

          entry ->
            {:noreply, select_entry(socket, entry, requested_slot_id)}
        end
    end
  end

  def handle_event("toggle_follow", _params, socket) do
    current_user = socket.assigns.current_user
    user = socket.assigns.user

    if socket.assigns.following do
      :ok = Accounts.unfollow_user(current_user, user)
    else
      _ = Accounts.follow_user(current_user, user)
    end

    {:noreply,
     socket
     |> assign(following: Accounts.following?(current_user, user))
     |> load_profile_entries()
     |> refresh_modal()}
  end

  def handle_event("select_slot", %{"slot_id" => slot_id}, socket) do
    {:noreply, assign(socket, :selected_slot_id, slot_id)}
  end

  def handle_event("book_slot", %{"booking" => booking_params}, socket) do
    cond do
      is_nil(socket.assigns.selected_entry) ->
        {:noreply, socket}

      is_nil(socket.assigns.selected_slot_id) ->
        {:noreply, put_flash(socket, :error, "Select a slot before booking.")}

      true ->
        attrs =
          booking_params
          |> Map.put("slot_id", socket.assigns.selected_slot_id)
          |> Map.put("user_id", socket.assigns.current_user.id)

        case Social.create_booking_from_post(socket.assigns.selected_entry.post, attrs) do
          {:ok, _booking} ->
            {:noreply,
             socket
             |> put_flash(:info, "Booking confirmed.")
             |> assign(:booking_form, booking_form(socket.assigns.current_user))
             |> load_profile_entries()
             |> refresh_modal()}

          {:error, %Ecto.Changeset{} = changeset} ->
            {:noreply, assign(socket, :booking_form, to_form(Map.put(changeset, :action, :insert), as: :booking))}

          {:error, reason} ->
            {:noreply, put_flash(socket, :error, Social.booking_error_message(reason))}
        end
    end
  end

  defp load_profile_entries(socket) do
    entries =
      socket.assigns.current_user
      |> Social.list_profile_posts(socket.assigns.user, 4)
      |> Enum.map(fn post ->
        bookable_slots = Social.list_upcoming_slots_for_post(post, @profile_window_days)
        weekly_slots = filter_slots_within_days(bookable_slots, 7)
        monthly_slots = filter_slots_for_current_month(bookable_slots)

        %{
          post: post,
          bookable_slots: bookable_slots,
          weekly_slots: weekly_slots,
          monthly_slots: monthly_slots,
          slot_count: length(bookable_slots)
        }
      end)

    assign(socket,
      profile_entries: entries,
      monthly_calendar: build_month_calendar(entries),
      weekly_calendar_days: build_week_calendar(entries)
    )
  end

  defp find_entry(entries, post_id) do
    Enum.find(entries, fn entry -> entry.post.id == post_id end)
  end

  defp select_entry(socket, entry, preferred_slot_id) do
    assign(socket,
      selected_entry: entry,
      selected_slot_id: resolve_selected_slot_id(entry.bookable_slots, preferred_slot_id),
      booking_form: booking_form(socket.assigns.current_user)
    )
  end

  defp refresh_modal(%{assigns: %{selected_entry: nil}} = socket), do: socket

  defp refresh_modal(socket) do
    case find_entry(socket.assigns.profile_entries, socket.assigns.selected_entry.post.id) do
      nil ->
        socket
        |> clear_modal()
        |> push_patch(to: profile_path(socket.assigns.user.id))

      entry ->
        select_entry(socket, entry, socket.assigns.selected_slot_id)
    end
  end

  defp clear_modal(socket) do
    assign(socket,
      selected_entry: nil,
      selected_slot_id: nil,
      booking_form: booking_form(socket.assigns.current_user)
    )
  end

  defp booking_form(current_user) do
    to_form(
      %{
        "customer_name" => current_user.name || "",
        "email" => current_user.email || "",
        "phone" => current_user.phone || ""
      },
      as: :booking
    )
  end

  defp build_week_calendar(entries) do
    days =
      Enum.map(0..6, fn offset ->
        date = Date.add(Date.utc_today(), offset)

        %{
          date: date,
          label: Calendar.strftime(date, "%a"),
          month_day: Calendar.strftime(date, "%b %d"),
          slots: [],
          slot_count: 0
        }
      end)

    slots_by_date =
      entries
      |> unique_calendar_slots(:weekly_slots)
      |> Enum.group_by(&slot_local_date/1)

    Enum.map(days, fn day ->
      slots = Map.get(slots_by_date, day.date, [])
      %{day | slots: slots, slot_count: length(slots)}
    end)
  end

  defp build_month_calendar(entries) do
    today = Date.utc_today()
    first_day = Date.new!(today.year, today.month, 1)
    last_day = Date.new!(today.year, today.month, Date.days_in_month(today))

    slots_by_date =
      entries
      |> unique_calendar_slots(:monthly_slots)
      |> Enum.group_by(&slot_local_date/1)

    leading_cells = List.duplicate(empty_calendar_cell(), max(Date.day_of_week(first_day) - 1, 0))

    day_cells =
      Enum.map(Date.range(first_day, last_day), fn date ->
        slots = Map.get(slots_by_date, date, [])

        %{
          date: date,
          day_number: date.day,
          slots: slots,
          slot_count: length(slots),
          outside_month: false,
          is_today: date == today,
          is_past: Date.before?(date, today)
        }
      end)

    total_cells = leading_cells ++ day_cells
    trailing_count = rem(7 - rem(length(total_cells), 7), 7)
    trailing_cells = List.duplicate(empty_calendar_cell(), trailing_count)
    weeks = Enum.chunk_every(total_cells ++ trailing_cells, 7)

    %{
      label: Calendar.strftime(first_day, "%B %Y"),
      day_headers: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
      total_slots: Enum.reduce(day_cells, 0, fn day, acc -> acc + day.slot_count end),
      weeks: weeks
    }
  end

  defp unique_calendar_slots(entries, slot_field) do
    entries
    |> Enum.reduce(%{}, fn entry, acc ->
      Enum.reduce(Map.fetch!(entry, slot_field), acc, fn slot, slot_acc ->
        slot_view =
          slot
          |> Map.put(:post_id, entry.post.id)
          |> Map.put(:post, entry.post)

        Map.put_new(slot_acc, slot.id, slot_view)
      end)
    end)
    |> Map.values()
    |> Enum.sort_by(&DateTime.to_unix(&1.start_time, :second))
  end

  defp filter_slots_within_days(slots, day_count) when is_integer(day_count) and day_count > 0 do
    cutoff = DateTime.add(DateTime.utc_now(), day_count * 24 * 60 * 60, :second)

    Enum.filter(slots, fn slot ->
      DateTime.compare(slot.start_time, cutoff) in [:lt, :eq]
    end)
  end

  defp filter_slots_for_current_month(slots) do
    today = Date.utc_today()
    month_start = Date.new!(today.year, today.month, 1)
    month_end = Date.new!(today.year, today.month, Date.days_in_month(today))

    Enum.filter(slots, fn slot ->
      slot_date = slot_local_date(slot)
      Date.compare(slot_date, month_start) != :lt and Date.compare(slot_date, month_end) != :gt
    end)
  end

  defp empty_calendar_cell do
    %{
      date: nil,
      day_number: nil,
      slots: [],
      slot_count: 0,
      outside_month: true,
      is_today: false,
      is_past: false
    }
  end

  defp resolve_selected_slot_id(slots, preferred_slot_id) do
    if Enum.any?(slots, fn slot -> slot.id == preferred_slot_id end) do
      preferred_slot_id
    else
      default_slot_id(slots)
    end
  end

  defp default_slot_id([slot | _]), do: slot.id
  defp default_slot_id([]), do: nil

  defp visibility_label(:public), do: "Public"
  defp visibility_label(:followers), do: "Followers"
  defp visibility_label(:private), do: "Private"

  defp relative_posted_at(inserted_at) do
    seconds = DateTime.diff(DateTime.utc_now(), to_datetime(inserted_at), :second)

    cond do
      seconds < 60 -> "Just now"
      seconds < 3_600 -> "#{div(seconds, 60)}m ago"
      seconds < 86_400 -> "#{div(seconds, 3_600)}h ago"
      true -> "#{div(seconds, 86_400)}d ago"
    end
  end

  defp to_datetime(%DateTime{} = value), do: value
  defp to_datetime(%NaiveDateTime{} = value), do: DateTime.from_naive!(value, "Etc/UTC")

  defp calendar_total_slots(days) do
    Enum.reduce(days, 0, fn day, acc -> acc + day.slot_count end)
  end

  defp calendar_time_range(slot) do
    post = Map.get(slot, :post)
    start_local = Social.post_local_datetime(post, slot.start_time)
    end_local = Social.post_local_datetime(post, slot.end_time)
    start_label = Calendar.strftime(start_local, "%H:%M")
    end_label = Calendar.strftime(end_local, "%H:%M")
    "#{start_label} - #{end_label}"
  end

  defp target_summary(post) do
    [post.service && "Service: #{post.service.name}", post.resource && "Resource: #{post.resource.name}"]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" | ")
  end

  defp slot_line_item(slot) do
    [present_label("Service", slot.service_name), present_label("Resource", slot.resource_name)]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" | ")
  end

  defp slot_price(slot) do
    total =
      [slot.service_price, slot.resource_price]
      |> Enum.reject(&is_nil/1)
      |> Enum.reduce(Decimal.new(0), &Decimal.add/2)

    "#{slot.currency || "KRW"} #{Decimal.to_string(total, :normal)}"
  end

  defp selected_slot_summary(post, slots, selected_slot_id) do
    case Enum.find(slots, fn slot -> slot.id == selected_slot_id end) do
      nil -> "Choose a slot to continue."
      slot -> "#{format_slot_datetime(post, slot.start_time, slot.end_time)} | #{slot_line_item(slot)}"
    end
  end

  defp format_slot_datetime(post, start_time, end_time) do
    start_local = Social.post_local_datetime(post, start_time)
    end_local = Social.post_local_datetime(post, end_time)
    start_label = Calendar.strftime(start_local, "%b %d, %a %H:%M")
    end_label = Calendar.strftime(end_local, "%H:%M")
    "#{start_label} - #{end_label} #{start_local.zone_abbr || start_local.time_zone}"
  end

  defp slot_local_date(slot) do
    slot
    |> Map.get(:post)
    |> Social.post_local_datetime(slot.start_time)
    |> DateTime.to_date()
  end

  defp slot_capacity(%{remaining_capacity: nil}), do: "Unlimited"
  defp slot_capacity(%{remaining_capacity: remaining_capacity}), do: "#{remaining_capacity} left"

  defp present_label(_label, nil), do: nil
  defp present_label(_label, ""), do: nil
  defp present_label(label, value), do: "#{label}: #{value}"

  defp profile_slot_path(user_id, post_id, slot_id), do: ~p"/profiles/#{user_id}?post_id=#{post_id}&slot_id=#{slot_id}"
  defp profile_post_path(user_id, post_id), do: ~p"/profiles/#{user_id}?post_id=#{post_id}"
  defp profile_path(user_id), do: ~p"/profiles/#{user_id}"
  defp share_path(post_id), do: ~p"/share/#{post_id}"
end
