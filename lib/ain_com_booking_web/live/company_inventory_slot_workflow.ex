defmodule AinComBookingWeb.CompanyInventorySlotWorkflow do
  @moduledoc false

  import AinComBookingWeb.CompanyConsoleComponents
  import Phoenix.Component, only: [assign: 3, to_form: 2]
  import Phoenix.LiveView, only: [put_flash: 3]

  alias AinComBooking.CompanyConsole.SlotGeneration
  alias AinComBookingWeb.CompanyInventoryState
  alias AinComBookingWeb.CompanyInventoryTarget

  def default_auto_slot_changeset(default_auto_slot_days, weekday_to_number) do
    auto_slot_changeset(
      %{
        "auto_slots_enabled" => true,
        "default_max_bookings" => nil,
        "schedule_start_date" => Date.add(Date.utc_today(), 1),
        "schedule_end_date" => Date.add(Date.utc_today(), default_auto_slot_days),
        "work_start_time" => ~T[09:00:00],
        "work_end_time" => ~T[18:00:00],
        "slot_minutes" => 60,
        "break_minutes" => 10,
        "lunch_start_time" => nil,
        "lunch_end_time" => nil,
        "available_weekdays" => "mon,tue,wed,thu,fri",
        "excluded_dates" => ""
      },
      weekday_to_number
    )
  end

  def open_manual_slot_modal(socket), do: {:noreply, CompanyInventoryState.open_manual_slot_modal(socket)}
  def close_manual_slot_modal(socket), do: {:noreply, CompanyInventoryState.close_manual_slot_modal(socket)}

  def manual_drag_select(socket, start_index, end_index) do
    max_slots = manual_slot_index_limit()

    with {:ok, parsed_start} <- parse_manual_slot_index(start_index, 0, max_slots - 1),
         {:ok, parsed_end} <- parse_manual_slot_index(end_index, 1, max_slots),
         true <- parsed_end > parsed_start do
      ranges =
        socket.assigns.manual_selected_ranges
        |> Kernel.++([%{start_index: parsed_start, end_index: parsed_end}])
        |> normalize_manual_slot_ranges()

      {:noreply, CompanyInventoryState.assign_manual_slot_state(socket, socket.assigns.manual_slot_date || Date.utc_today(), ranges, socket.assigns.manual_slot_max_bookings, nil)}
    else
      _ -> {:noreply, socket}
    end
  end

  def clear_manual_drag_ranges(socket) do
    {:noreply,
     CompanyInventoryState.assign_manual_slot_state(
       socket,
       socket.assigns.manual_slot_date || Date.utc_today(),
       [],
       socket.assigns.manual_slot_max_bookings,
       nil
     )}
  end

  def remove_manual_drag_range(socket, index) do
    ranges = remove_manual_slot_range(socket.assigns.manual_selected_ranges, index)

    {:noreply,
     CompanyInventoryState.assign_manual_slot_state(
       socket,
       socket.assigns.manual_slot_date || Date.utc_today(),
       ranges,
       socket.assigns.manual_slot_max_bookings,
       nil
     )}
  end

  def validate_manual_slot(socket, params) do
    selected_date = parse_manual_slot_date(params["selected_date"], socket.assigns.manual_slot_date || Date.utc_today())
    selected_ranges = if selected_date == socket.assigns.manual_slot_date, do: socket.assigns.manual_selected_ranges, else: []

    {:noreply,
     CompanyInventoryState.assign_manual_slot_state(
       socket,
       selected_date,
       selected_ranges,
       normalize_manual_slot_max_bookings(params["max_bookings"]),
       nil
     )}
  end

  def create_manual_slot(socket, params, default_manual_slot_minutes) do
    selected_date = parse_manual_slot_date(params["selected_date"], socket.assigns.manual_slot_date || Date.utc_today())
    selected_ranges = if selected_date == socket.assigns.manual_slot_date, do: socket.assigns.manual_selected_ranges, else: []

    with {:ok, max_bookings} <- parse_manual_slot_max_bookings(params["max_bookings"]),
         true <- selected_ranges != [],
         {:ok, day_start} <- DateTime.new(selected_date, ~T[00:00:00], "Etc/UTC") do
      existing_keys = MapSet.new(socket.assigns.service_slots, &slot_window_key(&1.start_time, &1.end_time))

      {created_count, skipped_count} =
        selected_ranges
        |> Enum.reduce({0, 0, existing_keys}, fn range, {created, skipped, seen_keys} ->
          start_time = manual_slot_datetime(day_start, range.start_index)
          end_time = manual_slot_datetime(day_start, range.end_index)
          window_key = slot_window_key(start_time, end_time)

          if MapSet.member?(seen_keys, window_key) do
            {created, skipped + 1, seen_keys}
          else
            attrs =
              CompanyInventoryTarget.manual_slot_attrs(
                socket.assigns.inventory_type,
                socket.assigns.service,
                %{"start_time" => start_time, "end_time" => end_time, "max_bookings" => max_bookings},
                default_manual_slot_minutes
              )

            case SlotGeneration.create_company_slot(socket.assigns.current_user, attrs) do
              {:ok, _slot} -> {created + 1, skipped, MapSet.put(seen_keys, window_key)}
              {:error, _changeset} -> {created, skipped + 1, seen_keys}
            end
          end
        end)
        |> then(fn {created, skipped, _seen_keys} -> {created, skipped} end)

      flash_type = if created_count > 0, do: :info, else: :error
      selected_ranges_after_create = if created_count > 0, do: [], else: selected_ranges

      {:noreply,
       socket
       |> put_flash(flash_type, manual_slot_result_message(created_count, skipped_count))
       |> assign(:show_manual_slot_modal, created_count == 0)
       |> CompanyInventoryState.assign_manual_slot_state(
         selected_date,
         selected_ranges_after_create,
         normalize_manual_slot_max_bookings(params["max_bookings"]),
         nil
       )
       |> assign_inventory_slot_state(socket.assigns.service,
         selected_date: selected_date,
         visible_month: month_start(selected_date)
       )}
    else
      false ->
        {:noreply,
         CompanyInventoryState.assign_manual_slot_state(
           socket,
           selected_date,
           selected_ranges,
           normalize_manual_slot_max_bookings(params["max_bookings"]),
           "드래그로 시간 구간을 1개 이상 선택해 주세요."
         )}

      {:error, :invalid_max_bookings} ->
        {:noreply,
         CompanyInventoryState.assign_manual_slot_state(
           socket,
           selected_date,
           selected_ranges,
           normalize_manual_slot_max_bookings(params["max_bookings"]),
           "최대 예약 수는 1 이상의 숫자여야 합니다."
         )}

      _ ->
        {:noreply,
         CompanyInventoryState.assign_manual_slot_state(
           socket,
           selected_date,
           selected_ranges,
           normalize_manual_slot_max_bookings(params["max_bookings"]),
           "선택한 날짜를 처리할 수 없습니다."
         )}
    end
  end

  def open_auto_slot_modal(socket, default_auto_slot_days, weekday_to_number) do
    changeset =
      (socket.assigns.auto_slot_form && socket.assigns.auto_slot_form.source) ||
        default_auto_slot_changeset(default_auto_slot_days, weekday_to_number)

    form = to_form(changeset, as: :auto_slot)
    excluded_date_inputs = excluded_date_inputs_from_changeset(changeset)

    {:noreply, CompanyInventoryState.open_auto_slot_modal(socket, form, excluded_date_inputs)}
  end

  def close_auto_slot_modal(socket), do: {:noreply, CompanyInventoryState.close_auto_slot_modal(socket)}

  def validate_auto_slot(socket, params, weekday_to_number) do
    excluded_date_inputs = excluded_date_inputs_from_params(params)
    normalized_params = normalize_auto_slot_params(params)

    changeset =
      normalized_params
      |> auto_slot_changeset(weekday_to_number)
      |> Map.put(:action, :validate)

    {:noreply,
     CompanyInventoryState.assign_auto_slot_form(
       socket,
       to_form(changeset, as: :auto_slot),
       excluded_date_inputs
     )}
  end

  def create_auto_slots(socket, params, default_auto_slot_days, weekday_to_number) do
    excluded_date_inputs = excluded_date_inputs_from_params(params)
    changeset = params |> normalize_auto_slot_params() |> auto_slot_changeset(weekday_to_number)

    if changeset.valid? do
      {created_count, skipped_count, focus_date} =
        CompanyInventoryTarget.create_auto_slots(
          socket.assigns.current_user,
          socket.assigns.inventory_type,
          socket.assigns.service,
          socket.assigns.service_slots,
          changeset,
          weekday_to_number
        )

      selected_date = focus_date || socket.assigns.selected_calendar_date
      visible_month = if selected_date, do: month_start(selected_date), else: socket.assigns.visible_calendar_month

      {:noreply,
       socket
       |> put_flash(:info, auto_slot_result_message(created_count, skipped_count))
       |> assign(:show_auto_slot_modal, false)
       |> CompanyInventoryState.assign_auto_slot_form(
         to_form(default_auto_slot_changeset(default_auto_slot_days, weekday_to_number), as: :auto_slot),
         [""]
       )
       |> assign_inventory_slot_state(socket.assigns.service,
         selected_date: selected_date,
         visible_month: visible_month
       )}
    else
      {:noreply,
       CompanyInventoryState.assign_auto_slot_form(
         socket,
         to_form(Map.put(changeset, :action, :insert), as: :auto_slot),
         excluded_date_inputs
       )}
    end
  end

  def add_auto_excluded_date(socket) do
    {:noreply, assign(socket, :auto_excluded_date_inputs, append_excluded_date_row(socket.assigns.auto_excluded_date_inputs))}
  end

  def remove_auto_excluded_date(socket, index) do
    {:noreply, assign(socket, :auto_excluded_date_inputs, remove_excluded_date_row(socket.assigns.auto_excluded_date_inputs, index))}
  end

  def select_calendar_date(socket, selected_date) do
    case Date.from_iso8601(selected_date) do
      {:ok, date} ->
        {:noreply,
         assign_inventory_slot_state(socket, socket.assigns.service,
           selected_date: date,
           visible_month: month_start(date)
         )}

      _ ->
        {:noreply, socket}
    end
  end

  def prev_calendar_month(socket) do
    target_month =
      socket.assigns.visible_calendar_month
      |> default_visible_month()
      |> shift_month(-1)

    {:noreply,
     assign_inventory_slot_state(socket, socket.assigns.service,
       selected_date: select_date_for_month(socket.assigns.selected_calendar_date, target_month),
       visible_month: target_month
     )}
  end

  def next_calendar_month(socket) do
    target_month =
      socket.assigns.visible_calendar_month
      |> default_visible_month()
      |> shift_month(1)

    {:noreply,
     assign_inventory_slot_state(socket, socket.assigns.service,
       selected_date: select_date_for_month(socket.assigns.selected_calendar_date, target_month),
       visible_month: target_month
     )}
  end

  defp auto_slot_changeset(attrs, weekday_to_number) when is_map(attrs) do
    types = %{
      auto_slots_enabled: :boolean,
      default_max_bookings: :integer,
      schedule_start_date: :date,
      schedule_end_date: :date,
      work_start_time: :time,
      work_end_time: :time,
      slot_minutes: :integer,
      break_minutes: :integer,
      lunch_start_time: :time,
      lunch_end_time: :time,
      available_weekdays: :string,
      excluded_dates: :string
    }

    {%{}, types}
    |> Ecto.Changeset.cast(attrs, Map.keys(types))
    |> Ecto.Changeset.validate_required([:schedule_start_date, :schedule_end_date, :work_start_time, :work_end_time, :slot_minutes, :break_minutes, :available_weekdays])
    |> Ecto.Changeset.validate_number(:slot_minutes, greater_than: 0, less_than_or_equal_to: 720)
    |> Ecto.Changeset.validate_number(:break_minutes, greater_than_or_equal_to: 0, less_than_or_equal_to: 180)
    |> Ecto.Changeset.validate_number(:default_max_bookings, greater_than: 0)
    |> Ecto.Changeset.validate_change(:available_weekdays, fn :available_weekdays, value ->
      if CompanyInventoryTarget.parse_weekdays(value, weekday_to_number) == [] do
        [available_weekdays: "select at least one weekday"]
      else
        []
      end
    end)
    |> validate_auto_slots_enabled()
    |> validate_auto_date_range()
    |> validate_auto_time_range()
    |> validate_lunch_time_range()
    |> validate_excluded_dates()
  end

  defp validate_auto_slots_enabled(changeset) do
    if Ecto.Changeset.get_field(changeset, :auto_slots_enabled) do
      changeset
    else
      Ecto.Changeset.add_error(changeset, :auto_slots_enabled, "must be enabled to generate slots")
    end
  end

  defp validate_auto_date_range(changeset) do
    start_date = Ecto.Changeset.get_field(changeset, :schedule_start_date)
    end_date = Ecto.Changeset.get_field(changeset, :schedule_end_date)

    cond do
      is_nil(start_date) or is_nil(end_date) -> changeset
      Date.compare(end_date, start_date) in [:eq, :gt] -> changeset
      true -> Ecto.Changeset.add_error(changeset, :schedule_end_date, "must be on or after start date")
    end
  end

  defp validate_auto_time_range(changeset) do
    work_start_time = Ecto.Changeset.get_field(changeset, :work_start_time)
    work_end_time = Ecto.Changeset.get_field(changeset, :work_end_time)

    cond do
      is_nil(work_start_time) or is_nil(work_end_time) -> changeset
      Time.after?(work_end_time, work_start_time) -> changeset
      true -> Ecto.Changeset.add_error(changeset, :work_end_time, "must be after work start time")
    end
  end

  defp validate_lunch_time_range(changeset) do
    lunch_start_time = Ecto.Changeset.get_field(changeset, :lunch_start_time)
    lunch_end_time = Ecto.Changeset.get_field(changeset, :lunch_end_time)
    work_start_time = Ecto.Changeset.get_field(changeset, :work_start_time)
    work_end_time = Ecto.Changeset.get_field(changeset, :work_end_time)

    cond do
      is_nil(lunch_start_time) and is_nil(lunch_end_time) ->
        changeset

      is_nil(lunch_start_time) or is_nil(lunch_end_time) ->
        changeset
        |> Ecto.Changeset.add_error(:lunch_start_time, "set both lunch start and lunch end")
        |> Ecto.Changeset.add_error(:lunch_end_time, "set both lunch start and lunch end")

      Time.compare(lunch_end_time, lunch_start_time) != :gt ->
        Ecto.Changeset.add_error(changeset, :lunch_end_time, "must be after lunch start")

      is_struct(work_start_time, Time) and Time.before?(lunch_start_time, work_start_time) ->
        Ecto.Changeset.add_error(changeset, :lunch_start_time, "must be within work hours")

      is_struct(work_end_time, Time) and Time.after?(lunch_end_time, work_end_time) ->
        Ecto.Changeset.add_error(changeset, :lunch_end_time, "must be within work hours")

      true ->
        changeset
    end
  end

  defp validate_excluded_dates(changeset) do
    value = Ecto.Changeset.get_field(changeset, :excluded_dates)

    case CompanyInventoryTarget.parse_excluded_dates(value) do
      {:ok, _dates} -> changeset
      {:error, _reason} -> Ecto.Changeset.add_error(changeset, :excluded_dates, "contains invalid date values")
    end
  end

  defp normalize_auto_slot_params(params) when is_map(params) do
    params
    |> Map.update("available_weekdays", "", &normalize_weekday_param/1)
    |> Map.update("excluded_dates", "", &normalize_excluded_date_param/1)
  end

  defp assign_inventory_slot_state(socket, service, opts) do
    slots = CompanyInventoryTarget.list_slots(socket.assigns.current_user, socket.assigns.inventory_type, service.id)

    CompanyInventoryState.put_slot_calendar(socket, :service_slots, slots, opts)
  end
end
