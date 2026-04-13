defmodule AinComBookingWeb.CompanyPublicBookingPageLive do
  @moduledoc false
  use AinComBookingWeb, :live_view

  alias AinComBooking.CompanyConsole

  @booking_window_days 30

  def render(assigns) do
    ~H"""
    <div class={page_shell_class(@page)}>
      <div class="mx-auto max-w-5xl px-4 py-10">
        <div :if={is_nil(@page)} class="rounded-3xl border border-dashed border-slate-300 bg-white px-6 py-12 text-center shadow-sm">
          <h1 class="text-2xl font-semibold tracking-tight text-slate-950">Booking Page Not Available</h1>
          <p class="mt-3 text-sm leading-6 text-slate-500">This page is missing, unpublished, or no longer valid.</p>
        </div>

        <div :if={@page} class="grid gap-6 lg:grid-cols-[minmax(0,1fr)_360px]">
          <section class="rounded-3xl border border-slate-200 bg-white p-6 shadow-sm">
            <div class="flex flex-wrap items-start justify-between gap-4">
              <div class="min-w-0 flex-1">
                <p class="text-xs font-semibold uppercase tracking-[0.22em] text-brand-600">Published Booking Page</p>
                <h1 class="mt-3 text-3xl font-semibold tracking-tight text-slate-950"><%= @page.title %></h1>
                <p :if={present?(@page.description)} class="mt-3 text-sm leading-7 text-slate-600"><%= @page.description %></p>
              </div>
              <div class="rounded-2xl bg-slate-50 px-4 py-4 text-right">
                <div class="text-xs font-semibold uppercase tracking-[0.18em] text-slate-400">Target</div>
                <div class="mt-2 text-sm font-semibold text-slate-950"><%= target_name(@page) %></div>
              </div>
            </div>

            <div class="mt-6">
              <div class="flex flex-wrap items-center justify-between gap-3">
                <div>
                  <h2 class="text-lg font-semibold tracking-tight text-slate-950">Choose A Date</h2>
                  <p class="mt-1 text-sm text-slate-500">Browse a full calendar and select a day to see bookable slots.</p>
                </div>
                <div class="flex items-center gap-3">
                  <span class="rounded-full bg-slate-100 px-3 py-1 text-[11px] font-semibold uppercase tracking-[0.16em] text-slate-500">
                    <%= CompanyConsole.company_timezone(@page) %>
                  </span>
                  <span class="text-sm font-semibold text-slate-500"><%= @calendar_month.total_slots %> open</span>
                </div>
              </div>

              <div class="mt-4 rounded-3xl border border-slate-200 bg-slate-50 p-4">
                <div class="flex items-center justify-between gap-3">
                  <button
                    type="button"
                    phx-click="prev_month"
                    disabled={!@calendar_month.can_prev}
                    class={calendar_nav_button_class(@calendar_month.can_prev)}
                  >
                    Prev
                  </button>
                  <div class="text-sm font-semibold tracking-[0.08em] text-slate-950"><%= @calendar_month.label %></div>
                  <button
                    type="button"
                    phx-click="next_month"
                    disabled={!@calendar_month.can_next}
                    class={calendar_nav_button_class(@calendar_month.can_next)}
                  >
                    Next
                  </button>
                </div>

                <div class="mt-5 grid grid-cols-7 gap-2">
                  <div
                    :for={label <- @calendar_month.day_headers}
                    class="px-2 text-center text-[11px] font-semibold uppercase tracking-[0.18em] text-slate-400"
                  >
                    <%= label %>
                  </div>
                </div>

                <div class="mt-2 space-y-2">
                  <div :for={week <- @calendar_month.weeks} class="grid grid-cols-7 gap-2">
                    <div
                      :for={day <- week}
                      class={[
                        "min-h-24 rounded-2xl border",
                        day.outside_month && "border-transparent bg-transparent",
                        !day.outside_month && "border-slate-200 bg-white"
                      ]}
                    >
                      <button
                        :if={!day.outside_month}
                        type="button"
                        phx-click="select_date"
                        phx-value-date={day.iso_date}
                        disabled={!day.selectable}
                        class={calendar_day_button_class(day)}
                      >
                        <span class="flex items-center justify-between gap-1">
                          <span class={[
                            "text-sm font-semibold",
                            day.is_selected && "text-white",
                            !day.is_selected && day.selectable && "text-slate-900",
                            !day.selectable && "text-slate-300"
                          ]}>
                            <%= day.day_number %>
                          </span>
                          <span class={[
                            "rounded-full px-1.5 py-0.5 text-[10px] font-semibold ring-1",
                            day.is_selected && "bg-white/10 text-white ring-white/20",
                            !day.is_selected && day.slot_count > 0 && "bg-brand-25 text-brand-700 ring-brand-100",
                            !day.is_selected && day.slot_count == 0 && "bg-white text-slate-400 ring-slate-200"
                          ]}>
                            <%= day.slot_count %>
                          </span>
                        </span>

                        <span class={[
                          "mt-2 block text-[11px] font-medium",
                          day.is_selected && "text-white/80",
                          !day.is_selected && day.slot_count > 0 && "text-slate-700",
                          !day.is_selected && day.slot_count == 0 && day.selectable && "text-slate-400",
                          !day.is_selected && !day.selectable && "text-slate-300"
                        ]}>
                          <%= if day.slot_count > 0, do: "Open slots", else: "No slots" %>
                        </span>
                      </button>
                    </div>
                  </div>
                </div>
              </div>

              <div class="mt-6 flex items-center justify-between gap-3">
                <h3 class="text-base font-semibold tracking-tight text-slate-950">Available Times</h3>
                <span class="text-sm font-semibold text-slate-500"><%= selected_date_label(@selected_date) %></span>
              </div>

              <div :if={@visible_slots == []} class="mt-3 rounded-2xl border border-dashed border-slate-300 bg-slate-50 px-4 py-6 text-sm text-slate-500">
                No open slots are available on the selected date.
              </div>

              <div :if={@visible_slots != []} class="mt-3 space-y-2">
                <button
                  :for={slot <- @visible_slots}
                  type="button"
                  phx-click="select_slot"
                  phx-value-slot_id={slot.id}
                  class={slot_button_class(slot.id == @selected_slot_id)}
                >
                  <span class="text-left">
                    <span class="block text-sm font-semibold text-slate-950"><%= slot_name(slot) %></span>
                    <span class="mt-1 block text-xs text-slate-400">
                      <%= slot_time(@page, slot) %>
                      ·
                      <%= slot_capacity(slot) %>
                    </span>
                  </span>
                  <span class="text-right text-sm font-semibold text-slate-950"><%= slot_price(slot) %></span>
                </button>
              </div>
            </div>
          </section>

          <aside class="rounded-3xl border border-slate-200 bg-white p-6 shadow-sm">
            <h2 class="text-lg font-semibold tracking-tight text-slate-950"><%= @page.button_label %></h2>
            <p class="mt-2 text-sm leading-6 text-slate-500">Complete the form below to reserve the selected time.</p>

            <.simple_form for={@booking_form} as={:booking} id="public-company-booking-form" phx-submit="book">
              <.input field={@booking_form[:customer_name]} type="text" label="Name" />
              <.input field={@booking_form[:email]} type="email" label="Email" />
              <.input field={@booking_form[:phone]} type="text" label="Phone" />

              <div class="rounded-2xl bg-slate-50 px-4 py-4">
                <div class="text-xs font-semibold uppercase tracking-[0.18em] text-slate-400">Selected Slot</div>
                <p class="mt-2 text-sm font-semibold text-slate-950"><%= selected_slot_summary(@page, @slots, @selected_slot_id) %></p>
              </div>

              <:actions>
                <.button
                  type="submit"
                  disabled={is_nil(@selected_slot_id)}
                  phx-disable-with="Booking..."
                  class="w-full rounded-full bg-slate-950 py-3 text-sm font-semibold text-white transition hover:bg-slate-800"
                >
                  Reserve This Slot
                </.button>
              </:actions>
            </.simple_form>
          </aside>
        </div>
      </div>
    </div>
    """
  end

  def mount(%{"slug" => slug}, _session, socket) do
    page = CompanyConsole.get_published_booking_page_by_slug(slug)
    slots = if page, do: CompanyConsole.list_upcoming_slots_for_page(page, @booking_window_days), else: []

    {:ok,
     socket
     |> assign(:booking_window_days, @booking_window_days)
     |> assign(:page, page)
     |> assign(:booking_form, blank_booking_form())
     |> assign_slot_state(page, slots)}
  end

  def handle_event("select_slot", %{"slot_id" => slot_id}, socket) do
    selected_slot_id =
      if Enum.any?(socket.assigns.visible_slots, fn slot -> slot.id == slot_id end) do
        slot_id
      else
        socket.assigns.selected_slot_id
      end

    {:noreply, assign(socket, :selected_slot_id, selected_slot_id)}
  end

  def handle_event("select_date", %{"date" => selected_date}, %{assigns: %{page: page, slots: slots}} = socket) do
    case Date.from_iso8601(selected_date) do
      {:ok, date} ->
        {:noreply, assign_slot_state(socket, page, slots, selected_date: date, selected_slot_id: nil, visible_month: month_start(date))}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("prev_month", _params, %{assigns: %{page: page, slots: slots, visible_month: visible_month, calendar_window: calendar_window}} = socket) do
    target_month = clamp_visible_month(shift_month(visible_month, -1), calendar_window)
    target_date = default_date_for_month(page, slots, calendar_window, target_month)

    {:noreply,
     assign_slot_state(socket, page, slots,
       selected_date: target_date,
       selected_slot_id: nil,
       visible_month: target_month
     )}
  end

  def handle_event("next_month", _params, %{assigns: %{page: page, slots: slots, visible_month: visible_month, calendar_window: calendar_window}} = socket) do
    target_month = clamp_visible_month(shift_month(visible_month, 1), calendar_window)
    target_date = default_date_for_month(page, slots, calendar_window, target_month)

    {:noreply,
     assign_slot_state(socket, page, slots,
       selected_date: target_date,
       selected_slot_id: nil,
       visible_month: target_month
     )}
  end

  def handle_event("book", %{"booking" => _params}, %{assigns: %{page: nil}} = socket) do
    {:noreply, put_flash(socket, :error, "This booking page is not available.")}
  end

  def handle_event("book", %{"booking" => params}, socket) do
    attrs = Map.put(params, "slot_id", socket.assigns.selected_slot_id)

    case CompanyConsole.create_booking_from_page(socket.assigns.page, attrs) do
      {:ok, _booking} ->
        slots = CompanyConsole.list_upcoming_slots_for_page(socket.assigns.page, @booking_window_days)

        {:noreply,
         socket
         |> put_flash(:info, "Your booking is confirmed.")
         |> assign(:booking_form, blank_booking_form())
         |> assign_slot_state(socket.assigns.page, slots,
           selected_date: socket.assigns.selected_date,
           selected_slot_id: nil,
           visible_month: socket.assigns.visible_month
         )}

      {:error, reason} ->
        {:noreply,
         socket
         |> put_flash(:error, CompanyConsole.booking_error_message(reason))
         |> assign(:booking_form, to_form(params, as: :booking))}
    end
  end

  defp blank_booking_form do
    to_form(
      %{
        "customer_name" => "",
        "email" => "",
        "phone" => ""
      },
      as: :booking
    )
  end

  defp assign_slot_state(socket, page, slots, opts \\ [])

  defp assign_slot_state(socket, nil, _slots, _opts) do
    socket
    |> assign(:slots, [])
    |> assign(:calendar_window, nil)
    |> assign(:visible_month, nil)
    |> assign(:calendar_month, empty_calendar_month())
    |> assign(:selected_date, nil)
    |> assign(:visible_slots, [])
    |> assign(:selected_slot_id, nil)
  end

  defp assign_slot_state(socket, page, slots, opts) do
    calendar_window = booking_calendar_window(page)
    selected_date = resolve_selected_date(page, slots, calendar_window, Keyword.get(opts, :selected_date))
    visible_month = resolve_visible_month(calendar_window, selected_date, Keyword.get(opts, :visible_month))
    calendar_month = build_calendar_month(page, slots, visible_month, calendar_window, selected_date)
    visible_slots = slots_for_date(page, slots, selected_date)
    selected_slot_id = resolve_selected_slot_id(visible_slots, Keyword.get(opts, :selected_slot_id))

    socket
    |> assign(:slots, slots)
    |> assign(:calendar_window, calendar_window)
    |> assign(:visible_month, visible_month)
    |> assign(:calendar_month, calendar_month)
    |> assign(:selected_date, selected_date)
    |> assign(:visible_slots, visible_slots)
    |> assign(:selected_slot_id, selected_slot_id)
  end

  defp resolve_selected_date(_page, _slots, calendar_window, %Date{} = preferred_date) do
    if date_within_window?(preferred_date, calendar_window) do
      preferred_date
    else
      calendar_window.start_date
    end
  end

  defp resolve_selected_date(page, slots, calendar_window, _preferred_date) do
    first_available_date =
      case slots do
        [slot | _rest] -> slot_local_date(page, slot)
        [] -> nil
      end

    if is_struct(first_available_date, Date) and date_within_window?(first_available_date, calendar_window) do
      first_available_date
    else
      calendar_window.start_date
    end
  end

  defp resolve_selected_slot_id([slot | _rest], nil), do: slot.id
  defp resolve_selected_slot_id([], _preferred_slot_id), do: nil

  defp resolve_selected_slot_id(visible_slots, preferred_slot_id) do
    if Enum.any?(visible_slots, fn slot -> slot.id == preferred_slot_id end) do
      preferred_slot_id
    else
      visible_slots
      |> List.first()
      |> case do
        nil -> nil
        slot -> slot.id
      end
    end
  end

  defp booking_calendar_window(page) do
    now = DateTime.utc_now()
    window_end = DateTime.add(now, @booking_window_days * 24 * 60 * 60, :second)
    start_date = now |> then(&CompanyConsole.page_local_datetime(page, &1)) |> DateTime.to_date()
    end_date = window_end |> then(&CompanyConsole.page_local_datetime(page, &1)) |> DateTime.to_date()

    %{
      start_date: start_date,
      end_date: end_date,
      start_month: month_start(start_date),
      end_month: month_start(end_date)
    }
  end

  defp build_calendar_month(page, slots, visible_month, calendar_window, selected_date) do
    first_day = visible_month
    last_day = Date.new!(visible_month.year, visible_month.month, Date.days_in_month(visible_month))

    slots_by_date = Enum.group_by(slots, &slot_local_date(page, &1))

    leading_cells = List.duplicate(empty_calendar_day(), max(Date.day_of_week(first_day) - 1, 0))

    day_cells =
      Enum.map(Date.range(first_day, last_day), fn date ->
        slot_count = slots_by_date |> Map.get(date, []) |> length()
        selectable = date_within_window?(date, calendar_window)

        %{
          date: date,
          iso_date: Date.to_iso8601(date),
          day_number: date.day,
          slot_count: slot_count,
          outside_month: false,
          selectable: selectable,
          is_today: date == calendar_window.start_date,
          is_selected: date == selected_date
        }
      end)

    total_cells = leading_cells ++ day_cells
    trailing_count = rem(7 - rem(length(total_cells), 7), 7)
    trailing_cells = List.duplicate(empty_calendar_day(), trailing_count)
    weeks = Enum.chunk_every(total_cells ++ trailing_cells, 7)

    %{
      label: Calendar.strftime(first_day, "%B %Y"),
      day_headers: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
      total_slots: Enum.reduce(day_cells, 0, fn day, acc -> acc + day.slot_count end),
      weeks: weeks,
      can_prev: Date.after?(first_day, calendar_window.start_month),
      can_next: Date.before?(first_day, calendar_window.end_month)
    }
  end

  defp resolve_visible_month(calendar_window, %Date{} = selected_date, nil) do
    selected_date
    |> month_start()
    |> clamp_visible_month(calendar_window)
  end

  defp resolve_visible_month(calendar_window, _selected_date, %Date{} = preferred_visible_month) do
    clamp_visible_month(preferred_visible_month, calendar_window)
  end

  defp resolve_visible_month(calendar_window, _selected_date, nil) do
    calendar_window.start_month
  end

  defp default_date_for_month(page, slots, calendar_window, month) do
    month_range_start = max_date(month, calendar_window.start_date)
    month_range_end = min_date(month_end(month), calendar_window.end_date)

    matching_date =
      slots
      |> Enum.map(&slot_local_date(page, &1))
      |> Enum.find(fn date ->
        Date.compare(date, month_range_start) != :lt and Date.compare(date, month_range_end) != :gt
      end)

    matching_date || month_range_start
  end

  defp date_within_window?(date, calendar_window) do
    Date.compare(date, calendar_window.start_date) != :lt and Date.compare(date, calendar_window.end_date) != :gt
  end

  defp clamp_visible_month(month, calendar_window) do
    cond do
      Date.before?(month, calendar_window.start_month) -> calendar_window.start_month
      Date.after?(month, calendar_window.end_month) -> calendar_window.end_month
      true -> month
    end
  end

  defp shift_month(%Date{} = month, offset) when is_integer(offset) do
    absolute_month = month.year * 12 + month.month - 1 + offset
    year = div(absolute_month, 12)
    month_number = rem(absolute_month, 12) + 1
    Date.new!(year, month_number, 1)
  end

  defp month_start(%Date{} = date), do: Date.new!(date.year, date.month, 1)
  defp month_end(%Date{} = date), do: Date.new!(date.year, date.month, Date.days_in_month(date))

  defp max_date(left, right) do
    if Date.before?(left, right), do: right, else: left
  end

  defp min_date(left, right) do
    if Date.after?(left, right), do: right, else: left
  end

  defp slots_for_date(_page, _slots, nil), do: []

  defp slots_for_date(page, slots, %Date{} = selected_date) do
    Enum.filter(slots, fn slot ->
      slot_local_date(page, slot) == selected_date
    end)
  end

  defp slot_local_date(page, slot) do
    page
    |> CompanyConsole.page_local_datetime(slot.start_time)
    |> DateTime.to_date()
  end

  defp selected_slot_summary(_page, _slots, nil), do: "Select an available date and time on the left."

  defp selected_slot_summary(page, slots, selected_slot_id) do
    case Enum.find(slots, fn slot -> slot.id == selected_slot_id end) do
      nil -> "Select an available date and time on the left."
      slot -> "#{slot_name(slot)} · #{slot_time(page, slot)}"
    end
  end

  defp target_name(%{service: %{name: name}}) when is_binary(name), do: "Service: #{name}"
  defp target_name(%{resource: %{name: name}}) when is_binary(name), do: "Resource: #{name}"
  defp target_name(_page), do: "Booking"

  defp slot_name(slot) do
    cond do
      present?(slot.service_name) and present?(slot.resource_name) -> "#{slot.service_name} + #{slot.resource_name}"
      present?(slot.service_name) -> slot.service_name
      present?(slot.resource_name) -> slot.resource_name
      true -> "Availability"
    end
  end

  defp slot_time(page, slot) do
    "#{format_datetime(page, slot.start_time)} to #{format_datetime(page, slot.end_time)}"
  end

  defp slot_price(slot) do
    service_price = slot.service_price || Decimal.new(0)
    resource_price = slot.resource_price || Decimal.new(0)
    total_price = Decimal.add(service_price, resource_price)
    "#{total_price} #{slot.currency || "KRW"}"
  end

  defp slot_capacity(%{remaining_capacity: nil}), do: "Unlimited"
  defp slot_capacity(%{remaining_capacity: remaining_capacity}), do: "#{remaining_capacity} left"

  defp format_datetime(_page, nil), do: "Unknown"

  defp format_datetime(page, %DateTime{} = datetime) do
    local_datetime = CompanyConsole.page_local_datetime(page, datetime)
    "#{Calendar.strftime(local_datetime, "%Y-%m-%d %H:%M")} #{local_datetime.zone_abbr || local_datetime.time_zone}"
  end

  defp slot_button_class(true) do
    "flex w-full items-center justify-between gap-4 rounded-2xl border border-slate-950 bg-slate-50 px-4 py-4 text-left"
  end

  defp slot_button_class(false) do
    "flex w-full items-center justify-between gap-4 rounded-2xl border border-slate-200 bg-white px-4 py-4 text-left transition hover:border-slate-300 hover:bg-slate-50"
  end

  defp calendar_nav_button_class(true) do
    "inline-flex items-center rounded-full border border-slate-200 bg-white px-3 py-1.5 text-xs font-semibold uppercase tracking-[0.18em] text-slate-600 transition hover:border-slate-300 hover:bg-slate-100"
  end

  defp calendar_nav_button_class(false) do
    "inline-flex items-center rounded-full border border-slate-200 bg-white px-3 py-1.5 text-xs font-semibold uppercase tracking-[0.18em] text-slate-300 opacity-60"
  end

  defp calendar_day_button_class(day) do
    [
      "flex h-full w-full flex-col rounded-2xl px-2.5 py-2 text-left transition",
      day.is_selected && "bg-slate-950 text-white",
      !day.is_selected && day.is_today && day.selectable && "bg-brand-25 hover:bg-brand-50",
      !day.is_selected && !day.is_today && day.selectable && "hover:bg-slate-50",
      !day.selectable && "cursor-not-allowed bg-slate-50"
    ]
  end

  defp empty_calendar_day do
    %{
      date: nil,
      iso_date: nil,
      day_number: nil,
      slot_count: 0,
      outside_month: true,
      selectable: false,
      is_today: false,
      is_selected: false
    }
  end

  defp empty_calendar_month do
    %{
      label: "",
      day_headers: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
      total_slots: 0,
      weeks: [],
      can_prev: false,
      can_next: false
    }
  end

  defp selected_date_label(nil), do: "No date selected"
  defp selected_date_label(%Date{} = date), do: Calendar.strftime(date, "%A, %B %d")

  defp page_shell_class(%{theme: "warm"}), do: "min-h-screen bg-gradient-to-b from-amber-50 via-white to-rose-50"
  defp page_shell_class(%{theme: "neutral"}), do: "min-h-screen bg-gradient-to-b from-slate-100 via-white to-slate-50"
  defp page_shell_class(_page), do: "min-h-screen bg-gradient-to-b from-brand-50 via-white to-slate-50"

  defp present?(value), do: value not in [nil, ""]
end
