defmodule AinComBookingWeb.CompanyConsoleComponents do
  @moduledoc false
  use AinComBookingWeb, :html

  @weekday_options [
    {"Mon", "mon"},
    {"Tue", "tue"},
    {"Wed", "wed"},
    {"Thu", "thu"},
    {"Fri", "fri"},
    {"Sat", "sat"},
    {"Sun", "sun"}
  ]
  @weekday_values Enum.map(@weekday_options, &elem(&1, 1))
  @manual_drag_step_minutes 15
  @calendar_day_headers ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
  @slot_minutes_options [
    {"15 minutes", 15},
    {"30 minutes", 30},
    {"45 minutes", 45},
    {"60 minutes", 60},
    {"90 minutes", 90},
    {"120 minutes", 120}
  ]
  @break_minutes_options [
    {"0 minutes", 0},
    {"5 minutes", 5},
    {"10 minutes", 10},
    {"15 minutes", 15},
    {"20 minutes", 20},
    {"30 minutes", 30},
    {"45 minutes", 45},
    {"60 minutes", 60}
  ]
  @work_time_options (for slot <- 0..47 do
                        hour =
                          slot
                          |> div(2)
                          |> Integer.to_string()
                          |> String.pad_leading(2, "0")

                        minute =
                          slot
                          |> rem(2)
                          |> Kernel.*(30)
                          |> Integer.to_string()
                          |> String.pad_leading(2, "0")

                        label = "#{hour}:#{minute}"
                        {label, label}
                      end)

  attr(:current_user, :map, required: true)
  attr(:company, :map, required: true)
  attr(:active_section, :atom, required: true)
  attr(:page_title, :string, required: true)
  attr(:page_label, :string, default: nil)
  attr(:page_subtitle, :string, default: nil)
  slot(:inner_block, required: true)
  slot(:sidebar)

  def shell(assigns) do
    ~H"""
    <style id="company-console-style">
      body > main[role="main"].p-6 {
        padding: 0;
      }

      body > main[role="main"].p-6 > .mb-4:empty {
        display: none;
        margin: 0;
      }

      .user-menu {
        display: none;
      }
    </style>

    <div class="min-h-screen bg-[#f7f9f9] font-outfit text-slate-900">
      <div class="mx-auto grid max-w-7xl gap-0 lg:grid-cols-[240px_minmax(0,1fr)]">
        <aside class="border-b border-slate-200 bg-slate-50 lg:min-h-screen lg:border-b-0 lg:border-r">
          <div class="flex h-full flex-col gap-4 px-4 py-4">
            <div class="rounded-3xl border border-slate-200 bg-white px-4 py-5 shadow-sm">
              <div class="text-xs font-semibold uppercase tracking-[0.22em] text-brand-600">Company Console</div>
              <div class="mt-3 text-2xl font-semibold tracking-tight text-slate-950"><%= @company.name || "Company" %></div>
              <p class="mt-2 text-sm leading-6 text-slate-500">
                Paid company customers manage services, resources, availability, and published booking pages from one place.
              </p>
            </div>

            <nav class="space-y-2 rounded-3xl border border-slate-200 bg-white p-3 shadow-sm">
              <.link navigate={~p"/company/console"} class={nav_item_class(@active_section == :dashboard)}>
                <.icon name="hero-squares-2x2" class="h-5 w-5" />
                <span class="text-sm font-semibold">Dashboard</span>
              </.link>
              <.link navigate={~p"/company/console/services"} class={nav_item_class(@active_section == :services)}>
                <.icon name="hero-briefcase" class="h-5 w-5" />
                <span class="text-sm font-semibold">Services</span>
              </.link>
              <.link navigate={~p"/company/console/resources"} class={nav_item_class(@active_section == :resources)}>
                <.icon name="hero-cube" class="h-5 w-5" />
                <span class="text-sm font-semibold">Resources</span>
              </.link>
            </nav>

            <section class="rounded-3xl border border-slate-200 bg-white p-3 shadow-sm">
              <div class="flex items-center gap-3 rounded-2xl px-2 py-2">
                <div class="flex h-11 w-11 shrink-0 items-center justify-center rounded-full bg-slate-950 text-sm font-semibold text-white">
                  <%= initials(@current_user.name) %>
                </div>

                <div class="min-w-0 flex-1">
                  <div class="truncate text-sm font-semibold text-slate-950"><%= @current_user.name || "Company User" %></div>
                  <div class="truncate text-xs text-slate-400"><%= @current_user.email %></div>
                </div>
              </div>

              <div class="mt-2 space-y-1">
                <.link
                  navigate={~p"/users/settings"}
                  class="flex items-center gap-3 rounded-2xl px-3 py-2 text-sm font-medium text-slate-500 transition hover:bg-slate-100 hover:text-slate-900"
                >
                  <.icon name="hero-cog-6-tooth" class="h-5 w-5" />
                  <span>Settings</span>
                </.link>
                <.link
                  href={~p"/users/log_out"}
                  method="delete"
                  class="flex items-center gap-3 rounded-2xl px-3 py-2 text-sm font-medium text-slate-500 transition hover:bg-slate-100 hover:text-slate-900"
                >
                  <.icon name="hero-arrow-left-on-rectangle" class="h-5 w-5" />
                  <span>Log out</span>
                </.link>
              </div>
            </section>
          </div>
        </aside>

        <main class="min-w-0 bg-white lg:min-h-screen">
          <div class="sticky top-0 z-10 border-b border-slate-200 bg-white/90 px-5 py-4 backdrop-blur">
            <div class="flex flex-wrap items-center justify-between gap-3">
              <div>
                <h1 class="text-2xl font-semibold tracking-tight text-slate-950"><%= @page_title %></h1>
                <p :if={@page_label} class="mt-1 text-xs font-medium uppercase tracking-[0.18em] text-slate-400"><%= @page_label %></p>
                <p :if={@page_subtitle} class="mt-2 text-sm leading-6 text-slate-500"><%= @page_subtitle %></p>
              </div>
            </div>
          </div>

          <div class="grid gap-0 xl:grid-cols-[minmax(0,1fr)_320px]">
            <section class="min-w-0 border-b border-slate-200 px-5 py-5 xl:border-b-0 xl:border-r">
              <%= render_slot(@inner_block) %>
            </section>

            <aside :if={@sidebar != []} class="bg-slate-50 px-5 py-5">
              <%= render_slot(@sidebar) %>
            </aside>
          </div>
        </main>
      </div>
    </div>
    """
  end

  defp nav_item_class(true), do: "flex items-center gap-3 rounded-2xl bg-slate-950 px-4 py-3 text-white transition"

  defp nav_item_class(false) do
    "flex items-center gap-3 rounded-2xl px-4 py-3 text-slate-500 transition hover:bg-slate-100 hover:text-slate-900"
  end

  defp initials(name) do
    name
    |> to_string()
    |> String.split(~r/\s+/, trim: true)
    |> Enum.take(2)
    |> Enum.map_join("", &String.first/1)
    |> case do
      "" -> "C"
      initials -> String.upcase(initials)
    end
  end

  attr(:field, Phoenix.HTML.FormField, required: true)
  attr(:label, :string, required: true)
  attr(:options, :list, default: [])
  attr(:prompt, :string, default: nil)

  def time_select_input(assigns) do
    field = assigns.field

    assigns =
      assigns
      |> assign(:id, field.id)
      |> assign(:name, field.name)
      |> assign(:value, normalize_time_value(field.value))
      |> assign(:errors, field_errors(field))

    ~H"""
    <div>
      <.label for={@id}>{@label}</.label>
      <select
        id={@id}
        name={@name}
        class={[
          "mt-2 block w-full rounded-md border bg-white shadow-sm focus:ring-0 sm:text-sm",
          @errors == [] && "border-gray-300 focus:border-zinc-400",
          @errors != [] && "border-rose-400 focus:border-rose-400"
        ]}
      >
        <option :if={@prompt} value="" selected={@value in [nil, ""]}>{@prompt}</option>
        {Phoenix.HTML.Form.options_for_select(@options, @value)}
      </select>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  attr(:field, Phoenix.HTML.FormField, required: true)

  def weekday_checkboxes(assigns) do
    field = assigns.field

    assigns =
      assigns
      |> assign(:id, field.id)
      |> assign(:name, field.name)
      |> assign(:errors, field_errors(field))
      |> assign(:selected_values, normalize_weekday_values(field.value))
      |> assign(:options, @weekday_options)

    ~H"""
    <div class="md:col-span-2">
      <.label for={"#{@id}-mon"}>Available weekdays</.label>
      <input type="hidden" name={@name <> "[]"} value="" />
      <div class="mt-3 flex flex-wrap gap-2">
        <label
          :for={{label, value} <- @options}
          for={"#{@id}-#{value}"}
          class={[
            "inline-flex cursor-pointer items-center rounded-full border px-3 py-2 text-sm font-semibold transition",
            value in @selected_values && "border-brand-600 bg-brand-50 text-brand-700",
            value not in @selected_values && "border-slate-300 bg-white text-slate-600 hover:border-slate-400 hover:text-slate-900"
          ]}
        >
          <input
            id={"#{@id}-#{value}"}
            type="checkbox"
            name={@name <> "[]"}
            value={value}
            checked={value in @selected_values}
            class="sr-only"
          />
          <span><%= label %></span>
        </label>
      </div>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def work_time_options, do: @work_time_options
  def slot_minutes_options, do: @slot_minutes_options
  def break_minutes_options, do: @break_minutes_options
  def manual_slot_index_limit, do: div(24 * 60, @manual_drag_step_minutes)
  def calendar_day_headers, do: @calendar_day_headers
  def weekday_values, do: @weekday_values

  def normalize_booking_page_params(params) when is_map(params) do
    params
    |> Map.update("available_weekdays", "", &normalize_weekday_param/1)
    |> Map.update("excluded_dates", "", &normalize_excluded_date_param/1)
    |> Map.update("default_max_bookings", nil, &normalize_optional_integer_param/1)
  end

  def normalize_weekday_param(value) do
    value
    |> normalize_weekday_values()
    |> Enum.join(",")
  end

  def normalize_weekday_values(nil), do: []
  def normalize_weekday_values(""), do: []

  def normalize_weekday_values(value) when is_binary(value) do
    value
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
    |> normalize_weekday_values()
  end

  def normalize_weekday_values(values) when is_list(values) do
    allowed = MapSet.new(@weekday_values)

    values
    |> Enum.reduce(MapSet.new(), fn
      value, acc when is_binary(value) ->
        trimmed = String.trim(value)

        if trimmed == "" or not MapSet.member?(allowed, trimmed) do
          acc
        else
          MapSet.put(acc, trimmed)
        end

      _, acc ->
        acc
    end)
    |> then(fn selected ->
      Enum.filter(@weekday_values, &MapSet.member?(selected, &1))
    end)
  end

  def normalize_excluded_date_param(value) do
    value
    |> normalize_excluded_date_values()
    |> Enum.join(",")
  end

  def normalize_excluded_date_values(nil), do: []
  def normalize_excluded_date_values(""), do: []

  def normalize_excluded_date_values(value) when is_binary(value) do
    value
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
    |> normalize_excluded_date_values()
  end

  def normalize_excluded_date_values(values) when is_list(values) do
    values
    |> Enum.reduce(MapSet.new(), fn
      value, acc when is_binary(value) ->
        trimmed = String.trim(value)

        case Date.from_iso8601(trimmed) do
          {:ok, _date} -> MapSet.put(acc, trimmed)
          _ -> acc
        end

      _, acc ->
        acc
    end)
    |> MapSet.to_list()
    |> Enum.sort()
  end

  def normalize_optional_integer_param(nil), do: nil
  def normalize_optional_integer_param(""), do: nil
  def normalize_optional_integer_param(value), do: value

  def booking_page_status_badge_class(true), do: "rounded-full bg-emerald-50 px-2.5 py-1 text-[11px] font-semibold text-emerald-700"
  def booking_page_status_badge_class(false), do: "rounded-full bg-amber-50 px-2.5 py-1 text-[11px] font-semibold text-amber-700"
  def booking_page_auto_badge_class(true), do: "rounded-full bg-indigo-50 px-2.5 py-1 text-[11px] font-semibold text-indigo-700"
  def booking_page_auto_badge_class(false), do: "rounded-full bg-slate-100 px-2.5 py-1 text-[11px] font-semibold text-slate-600"

  def booking_page_slug_seed(name, empty_fallback) do
    name
    |> to_string()
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/u, "-")
    |> String.trim("-")
    |> case do
      "" -> empty_fallback
      slug -> "#{slug}-booking"
    end
  end

  def manual_hour_stats(_slots, nil), do: %{}

  def manual_hour_stats(slots, %Date{} = date) do
    slots
    |> Enum.filter(fn slot -> slot_date(slot) == date and match?(%DateTime{}, slot.start_time) end)
    |> Enum.reduce(%{}, fn slot, acc ->
      hour = slot.start_time.hour
      slot_count = 1
      booking_count = slot_booking_count(slot)

      Map.update(acc, hour, %{slot_count: slot_count, booking_count: booking_count}, fn current ->
        %{
          slot_count: current.slot_count + slot_count,
          booking_count: current.booking_count + booking_count
        }
      end)
    end)
  end

  def hour_slot_count(stats, hour), do: stats |> Map.get(hour, %{slot_count: 0}) |> Map.get(:slot_count, 0)
  def hour_booking_count(stats, hour), do: stats |> Map.get(hour, %{booking_count: 0}) |> Map.get(:booking_count, 0)

  def manual_time_segments do
    for index <- 0..(manual_slot_index_limit() - 1) do
      total_minutes = index * @manual_drag_step_minutes
      hour = div(total_minutes, 60)
      minute = rem(total_minutes, 60)

      %{
        index: index,
        hour: hour,
        minute: minute,
        label: if(minute == 0, do: manual_index_label(index), else: "")
      }
    end
  end

  def manual_segment_selected?(ranges, index) do
    Enum.any?(ranges, fn range -> index >= range.start_index and index < range.end_index end)
  end

  def manual_segment_minute_label(minute), do: String.pad_leading(Integer.to_string(minute), 2, "0")

  def manual_slot_range_label(%{start_index: start_index, end_index: end_index}) do
    "#{manual_index_label(start_index)} - #{manual_index_label(end_index)}"
  end

  def manual_index_label(index) when is_integer(index) and index >= 0 do
    total_minutes = index * @manual_drag_step_minutes
    hour = div(total_minutes, 60)
    minute = rem(total_minutes, 60)
    "#{String.pad_leading(Integer.to_string(hour), 2, "0")}:#{String.pad_leading(Integer.to_string(minute), 2, "0")}"
  end

  def manual_slot_datetime(day_start, index) do
    DateTime.add(day_start, index * @manual_drag_step_minutes * 60, :second)
  end

  def date_input_value(nil), do: ""
  def date_input_value(%Date{} = date), do: Date.to_iso8601(date)

  def resolve_selected_date(_slots, %Date{} = preferred_date), do: preferred_date

  def resolve_selected_date(slots, _preferred_date) do
    case Enum.find(slots, &match?(%DateTime{}, &1.start_time)) do
      %{start_time: %DateTime{} = start_time} -> DateTime.to_date(start_time)
      _ -> Date.utc_today()
    end
  end

  def resolve_visible_month(%Date{} = selected_date, nil), do: month_start(selected_date)
  def resolve_visible_month(_selected_date, %Date{} = preferred_visible_month), do: month_start(preferred_visible_month)

  def default_visible_month(nil), do: month_start(Date.utc_today())
  def default_visible_month(%Date{} = month), do: month_start(month)

  def select_date_for_month(%Date{} = selected_date, %Date{} = month) do
    if selected_date.year == month.year and selected_date.month == month.month do
      selected_date
    else
      month
    end
  end

  def select_date_for_month(_selected_date, %Date{} = month), do: month

  def build_calendar_month(slots, visible_month, selected_date) do
    first_day = month_start(visible_month)
    last_day = month_end(visible_month)
    slots_by_date = Enum.group_by(slots, &slot_date/1)

    leading_cells = List.duplicate(empty_calendar_day(), max(Date.day_of_week(first_day) - 1, 0))

    day_cells =
      Enum.map(Date.range(first_day, last_day), fn date ->
        day_slots = Map.get(slots_by_date, date, [])

        slot_count = length(day_slots)
        booking_count = Enum.reduce(day_slots, 0, fn slot, acc -> slot_booking_count(slot) + acc end)

        %{
          date: date,
          iso_date: Date.to_iso8601(date),
          day_number: date.day,
          slot_count: slot_count,
          booking_count: booking_count,
          outside_month: false,
          is_today: date == Date.utc_today(),
          is_selected: date == selected_date
        }
      end)

    total_cells = leading_cells ++ day_cells
    trailing_count = rem(7 - rem(length(total_cells), 7), 7)
    trailing_cells = List.duplicate(empty_calendar_day(), trailing_count)

    %{
      label: Calendar.strftime(first_day, "%B %Y"),
      day_headers: @calendar_day_headers,
      weeks: Enum.chunk_every(total_cells ++ trailing_cells, 7)
    }
  end

  def empty_calendar_month do
    %{
      label: "",
      day_headers: @calendar_day_headers,
      weeks: []
    }
  end

  def empty_calendar_day do
    %{
      date: nil,
      iso_date: nil,
      day_number: nil,
      slot_count: 0,
      booking_count: 0,
      outside_month: true,
      is_today: false,
      is_selected: false
    }
  end

  def slots_for_date(slots, %Date{} = selected_date) do
    slots
    |> Enum.filter(&(slot_date(&1) == selected_date))
    |> Enum.sort_by(fn slot -> DateTime.to_unix(slot.start_time) end, :asc)
  end

  def slot_date(%{start_time: %DateTime{} = start_time}), do: DateTime.to_date(start_time)
  def slot_date(_slot), do: Date.utc_today()

  def slot_window_key(%DateTime{} = start_time, %DateTime{} = end_time) do
    "#{DateTime.to_unix(start_time)}:#{DateTime.to_unix(end_time)}"
  end

  def slot_window_key(_, _), do: ""

  def shift_month(%Date{} = month, offset) when is_integer(offset) do
    absolute_month = month.year * 12 + month.month - 1 + offset
    year = div(absolute_month, 12)
    month_number = rem(absolute_month, 12) + 1
    Date.new!(year, month_number, 1)
  end

  def month_start(%Date{} = date), do: Date.new!(date.year, date.month, 1)
  def month_end(%Date{} = date), do: Date.new!(date.year, date.month, Date.days_in_month(date))

  def selected_date_label(nil), do: "No date selected"
  def selected_date_label(%Date{} = date), do: Calendar.strftime(date, "%A, %B %d")

  def slot_time_range(slot) do
    "#{format_slot_datetime(slot.start_time)} to #{format_slot_datetime(slot.end_time)}"
  end

  def format_slot_datetime(nil), do: "Unknown"
  def format_slot_datetime(%DateTime{} = datetime), do: Calendar.strftime(datetime, "%Y-%m-%d %H:%M UTC")

  def booking_slot_window(%{slot: %{start_time: start_time, end_time: end_time}}) do
    "#{format_slot_datetime(start_time)} to #{format_slot_datetime(end_time)}"
  end

  def booking_slot_window(_booking), do: "Slot details unavailable"

  def booking_status_badge_class("confirmed"), do: "rounded-full bg-emerald-50 px-2 py-0.5 text-[11px] font-semibold uppercase tracking-[0.16em] text-emerald-700"
  def booking_status_badge_class("cancelled"), do: "rounded-full bg-rose-50 px-2 py-0.5 text-[11px] font-semibold uppercase tracking-[0.16em] text-rose-700"
  def booking_status_badge_class("noshow"), do: "rounded-full bg-amber-50 px-2 py-0.5 text-[11px] font-semibold uppercase tracking-[0.16em] text-amber-700"
  def booking_status_badge_class(_status), do: "rounded-full bg-slate-100 px-2 py-0.5 text-[11px] font-semibold uppercase tracking-[0.16em] text-slate-500"

  def slot_capacity_label(%{max_bookings: nil}), do: "Unlimited"
  def slot_capacity_label(%{max_bookings: max_bookings}), do: "Max #{max_bookings} bookings"

  def slot_booking_count_label(slot) do
    count = slot_booking_count(slot)
    if count == 1, do: "1 booking", else: "#{count} bookings"
  end

  def slot_booking_count(%{booking_count: count}) when is_integer(count) and count > 0, do: count
  def slot_booking_count(_slot), do: 0

  def slot_status_label(:available), do: "Available"
  def slot_status_label(:booked), do: "Booked"
  def slot_status_label(:cancelled), do: "Cancelled"
  def slot_status_label(value), do: value |> to_string() |> String.capitalize()

  def slot_source_label(:generated), do: "Auto"
  def slot_source_label(:manual), do: "Manual"
  def slot_source_label(_value), do: "Manual"

  def slot_status_badge_class(:available), do: "rounded-full bg-emerald-50 px-2 py-0.5 text-[11px] font-semibold text-emerald-700"
  def slot_status_badge_class(:booked), do: "rounded-full bg-brand-50 px-2 py-0.5 text-[11px] font-semibold text-brand-700"
  def slot_status_badge_class(:cancelled), do: "rounded-full bg-slate-100 px-2 py-0.5 text-[11px] font-semibold text-slate-500"
  def slot_status_badge_class(_), do: "rounded-full bg-slate-100 px-2 py-0.5 text-[11px] font-semibold text-slate-500"

  def slot_source_badge_class(:generated), do: "rounded-full bg-indigo-50 px-2 py-0.5 text-[11px] font-semibold text-indigo-700"
  def slot_source_badge_class(_), do: "rounded-full bg-slate-100 px-2 py-0.5 text-[11px] font-semibold text-slate-600"

  def calendar_nav_button_class do
    "inline-flex items-center rounded-full border border-slate-200 bg-white px-3 py-1.5 text-xs font-semibold uppercase tracking-[0.18em] text-slate-600 transition hover:border-slate-300 hover:bg-slate-100"
  end

  def calendar_day_button_class(day) do
    [
      "flex h-full w-full flex-col rounded-2xl px-2.5 py-2 text-left transition",
      day.is_selected && "bg-slate-950 text-white",
      !day.is_selected && day.is_today && "bg-brand-25 hover:bg-brand-50",
      !day.is_selected && !day.is_today && "hover:bg-slate-50"
    ]
  end

  def excluded_date_inputs_from_changeset(changeset) do
    changeset
    |> Ecto.Changeset.get_field(:excluded_dates)
    |> normalize_excluded_date_values()
    |> ensure_excluded_date_input_row()
  end

  def excluded_date_inputs_from_params(params) when is_map(params) do
    params
    |> Map.get("excluded_dates")
    |> normalize_excluded_date_values()
    |> ensure_excluded_date_input_row()
  end

  def append_excluded_date_row(values) do
    rows =
      case values do
        list when is_list(list) and list != [] -> list
        _ -> [""]
      end

    rows ++ [""]
  end

  def remove_excluded_date_row(values, index) do
    case Integer.parse(to_string(index)) do
      {index_value, ""} ->
        values
        |> List.delete_at(index_value)
        |> ensure_excluded_date_input_row()

      _ ->
        ensure_excluded_date_input_row(values)
    end
  end

  def ensure_excluded_date_input_row(values) when is_list(values) do
    case Enum.reject(values, &(&1 == "")) do
      [] -> [""]
      sanitized -> sanitized
    end
  end

  def auto_slot_result_message(created_count, skipped_count) do
    "자동 slot #{created_count}개 생성, #{skipped_count}개 건너뜀(중복/검증 실패)."
  end

  def manual_slot_result_message(created_count, skipped_count) do
    "수동 slot #{created_count}개 생성, #{skipped_count}개 건너뜀(중복/검증 실패)."
  end

  def parse_manual_slot_date(value, fallback_date) do
    case Date.from_iso8601(to_string(value || "")) do
      {:ok, date} -> date
      _ -> fallback_date
    end
  end

  def parse_manual_slot_max_bookings(value) do
    value = normalize_manual_slot_max_bookings(value)

    if value == "" do
      {:ok, nil}
    else
      case Integer.parse(value) do
        {parsed, ""} when parsed > 0 -> {:ok, parsed}
        _ -> {:error, :invalid_max_bookings}
      end
    end
  end

  def normalize_manual_slot_max_bookings(nil), do: ""
  def normalize_manual_slot_max_bookings(value), do: String.trim(to_string(value))

  def parse_manual_slot_index(value, min_value, max_value) do
    case Integer.parse(to_string(value || "")) do
      {parsed, ""} when parsed >= min_value and parsed <= max_value -> {:ok, parsed}
      _ -> {:error, :invalid_index}
    end
  end

  def normalize_manual_slot_ranges(ranges) when is_list(ranges) do
    max_slots = manual_slot_index_limit()

    ranges
    |> Enum.filter(fn
      %{start_index: start_index, end_index: end_index}
      when is_integer(start_index) and is_integer(end_index) and start_index >= 0 and end_index <= max_slots and start_index < end_index ->
        true

      _ ->
        false
    end)
    |> Enum.sort_by(fn range -> {range.start_index, range.end_index} end)
    |> Enum.reduce([], fn range, acc ->
      case acc do
        [%{start_index: current_start, end_index: current_end} | tail] ->
          if range.start_index < current_end do
            [%{start_index: current_start, end_index: max(current_end, range.end_index)} | tail]
          else
            [range | acc]
          end

        [] ->
          [range]
      end
    end)
    |> Enum.reverse()
  end

  def remove_manual_slot_range(ranges, index) do
    case Integer.parse(to_string(index)) do
      {index_value, ""} ->
        ranges
        |> List.delete_at(index_value)
        |> normalize_manual_slot_ranges()

      _ ->
        ranges
    end
  end

  def stringify_keys(attrs) when is_map(attrs) do
    Map.new(attrs, fn {key, value} -> {to_string(key), value} end)
  end

  defp field_errors(field) do
    if Phoenix.Component.used_input?(field) do
      Enum.map(field.errors, &translate_error/1)
    else
      []
    end
  end

  defp normalize_time_value(nil), do: nil
  defp normalize_time_value(""), do: ""
  defp normalize_time_value(%Time{} = value), do: Calendar.strftime(value, "%H:%M")
  defp normalize_time_value(value) when is_binary(value), do: value
end
