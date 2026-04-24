defmodule AinComBookingWeb.CompanyInventoryTarget do
  @moduledoc false

  alias AinComBooking.Catalog.CompanyResource
  alias AinComBooking.Catalog.CompanyService
  alias AinComBooking.CompanyConsole.BookingPage
  alias AinComBooking.CompanyConsole.BookingPages
  alias AinComBooking.CompanyConsole.Bookings
  alias AinComBooking.CompanyConsole.Inventory
  alias AinComBooking.CompanyConsole.SlotGeneration
  import Phoenix.Component, only: [assign: 3, to_form: 2]
  import AinComBookingWeb.CompanyConsoleComponents, only: [slot_window_key: 2, stringify_keys: 1, booking_page_slug_seed: 2]

  def list_inventory_items(user, :service), do: Inventory.list_company_services(user)
  def list_inventory_items(user, :resource), do: Inventory.list_company_resources(user)

  def get_inventory_item(user, :service, id), do: Inventory.get_company_service(user, id)
  def get_inventory_item(user, :resource, id), do: Inventory.get_company_resource(user, id)

  def create_inventory_item(user, :service, params), do: Inventory.create_company_service(user, params)
  def create_inventory_item(user, :resource, params), do: Inventory.create_company_resource(user, params)

  def update_inventory_item(:service, inventory, params), do: Inventory.update_company_service(inventory, params)
  def update_inventory_item(:resource, inventory, params), do: Inventory.update_company_resource(inventory, params)

  def delete_inventory_item(:service, inventory), do: Inventory.delete_company_service(inventory)
  def delete_inventory_item(:resource, inventory), do: Inventory.delete_company_resource(inventory)

  def change_inventory_item(user, :service, inventory), do: Inventory.change_company_service(user, inventory)
  def change_inventory_item(user, :resource, inventory), do: Inventory.change_company_resource(user, inventory)

  def list_inventory_bookings(user, :service, id), do: Bookings.list_company_bookings_for_service(user, id)
  def list_inventory_bookings(user, :resource, id), do: Bookings.list_company_bookings_for_resource(user, id)

  def create_booking_page_for_inventory(user, :service, id, params), do: BookingPages.create_booking_page_for_service(user, id, params)
  def create_booking_page_for_inventory(user, :resource, id, params), do: BookingPages.create_booking_page_for_resource(user, id, params)

  def inventory_changeset_for_action(%{assigns: %{live_action: :new, current_user: user, inventory_type: :service}}, params) do
    Inventory.change_company_service(user, %CompanyService{}, params)
  end

  def inventory_changeset_for_action(%{assigns: %{live_action: :new, current_user: user, inventory_type: :resource}}, params) do
    Inventory.change_company_resource(user, %CompanyResource{}, params)
  end

  def inventory_changeset_for_action(%{assigns: %{current_user: user, inventory_type: :service, service: service}}, params) do
    Inventory.change_company_service(user, service, params)
  end

  def inventory_changeset_for_action(%{assigns: %{current_user: user, inventory_type: :resource, service: service}}, params) do
    Inventory.change_company_resource(user, service, params)
  end

  def default_inventory_changeset(user, :service) do
    Inventory.change_company_service(user, %CompanyService{}, %{
      "name" => "",
      "description_text" => "",
      "duration" => 30,
      "hide_duration" => false,
      "is_active" => true,
      "is_public" => true,
      "is_recurring" => false,
      "price" => "0.00",
      "currency" => "KRW"
    })
  end

  def default_inventory_changeset(user, :resource) do
    Inventory.change_company_resource(user, %CompanyResource{}, %{
      "name" => "",
      "type" => "",
      "location" => "",
      "description" => "",
      "price" => "0.00",
      "currency" => "KRW"
    })
  end

  def form_for_action(_user, :show, _inventory), do: nil
  def form_for_action(_user, :delete, _inventory), do: nil

  def form_for_action(user, :edit, inventory) do
    inventory_type = infer_inventory_type(inventory)

    change_inventory_item(user, inventory_type, inventory)
    |> to_form(as: inventory_type)
  end

  def inventory_stats(:service, inventories) do
    %{
      total: length(inventories),
      active: Enum.count(inventories, & &1.is_active),
      public: Enum.count(inventories, & &1.is_public)
    }
  end

  def inventory_stats(:resource, inventories) do
    %{
      total: length(inventories),
      located: Enum.count(inventories, &present?(&1.location)),
      priced: Enum.count(inventories, &(not is_nil(&1.price)))
    }
  end

  def infer_inventory_type(%CompanyResource{}), do: :resource
  def infer_inventory_type(_inventory), do: :service

  def list_slots(user, :service, service_id) do
    list_target_slots(user, fn slot -> slot.service_id == service_id end)
  end

  def list_slots(user, :resource, resource_id) do
    list_target_slots(user, fn slot -> slot.resource_id == resource_id end)
  end

  def manual_slot_attrs(:service, %CompanyService{} = service, attrs, default_manual_slot_minutes) when is_map(attrs) do
    attrs = stringify_keys(attrs)
    default_start = Map.get(attrs, "start_time") || default_manual_slot_start()

    attrs
    |> Map.put_new("start_time", default_start)
    |> Map.put_new("end_time", default_manual_slot_end(default_start, service, default_manual_slot_minutes))
    |> Map.put("status", "available")
    |> Map.put("source_type", "manual")
    |> Map.put("service_id", service.id)
    |> Map.put("resource_id", nil)
  end

  def manual_slot_attrs(:resource, %CompanyResource{} = resource, attrs, default_manual_slot_minutes) when is_map(attrs) do
    attrs = stringify_keys(attrs)
    default_start = Map.get(attrs, "start_time") || default_manual_slot_start()

    attrs
    |> Map.put_new("start_time", default_start)
    |> Map.put_new("end_time", DateTime.add(default_start, default_manual_slot_minutes * 60, :second))
    |> Map.put("status", "available")
    |> Map.put("source_type", "manual")
    |> Map.put("service_id", nil)
    |> Map.put("resource_id", resource.id)
  end

  def create_auto_slots(user, :service, %CompanyService{} = service, existing_slots, changeset, weekday_to_number) do
    config = auto_slot_config(changeset, weekday_to_number)
    existing_keys = MapSet.new(existing_slots, &slot_window_key(&1.start_time, &1.end_time))
    windows = build_auto_slot_windows(config)

    {created_count, skipped_count, selected_date, _seen_keys} =
      Enum.reduce(windows, {0, 0, nil, existing_keys}, fn window, {created, skipped, focus_date, seen_keys} ->
        window_key = slot_window_key(window.start_time, window.end_time)

        if MapSet.member?(seen_keys, window_key) do
          {created, skipped + 1, focus_date, seen_keys}
        else
          attrs = %{
            "start_time" => window.start_time,
            "end_time" => window.end_time,
            "status" => "available",
            "source_type" => "manual",
            "max_bookings" => config.max_bookings,
            "service_id" => service.id,
            "resource_id" => nil
          }

          case SlotGeneration.create_company_slot(user, attrs) do
            {:ok, slot} ->
              first_date = focus_date || DateTime.to_date(slot.start_time)
              {created + 1, skipped, first_date, MapSet.put(seen_keys, window_key)}

            {:error, _changeset} ->
              {created, skipped + 1, focus_date, seen_keys}
          end
        end
      end)

    {created_count, skipped_count, selected_date}
  end

  def create_auto_slots(user, :resource, %CompanyResource{} = resource, existing_slots, changeset, weekday_to_number) do
    config = auto_slot_config(changeset, weekday_to_number)
    existing_keys = MapSet.new(existing_slots, &slot_window_key(&1.start_time, &1.end_time))
    windows = build_auto_slot_windows(config)

    {created_count, skipped_count, selected_date, _seen_keys} =
      Enum.reduce(windows, {0, 0, nil, existing_keys}, fn window, {created, skipped, focus_date, seen_keys} ->
        window_key = slot_window_key(window.start_time, window.end_time)

        if MapSet.member?(seen_keys, window_key) do
          {created, skipped + 1, focus_date, seen_keys}
        else
          attrs = %{
            "start_time" => window.start_time,
            "end_time" => window.end_time,
            "status" => "available",
            "source_type" => "manual",
            "max_bookings" => config.max_bookings,
            "service_id" => nil,
            "resource_id" => resource.id
          }

          case SlotGeneration.create_company_slot(user, attrs) do
            {:ok, slot} ->
              first_date = focus_date || DateTime.to_date(slot.start_time)
              {created + 1, skipped, first_date, MapSet.put(seen_keys, window_key)}

            {:error, _changeset} ->
              {created, skipped + 1, focus_date, seen_keys}
          end
        end
      end)

    {created_count, skipped_count, selected_date}
  end

  def parse_weekdays(value, weekday_to_number) do
    do_parse_weekdays(value, weekday_to_number)
  end

  def parse_excluded_dates(value) do
    do_parse_excluded_dates(value)
  end

  def fetch_booking_page(_user, _target_type, _target, nil), do: {:error, :not_found}

  def fetch_booking_page(user, :service, %CompanyService{} = service, page_id) do
    service_id = service.id

    case BookingPages.get_booking_page(user, page_id) do
      %BookingPage{service_id: ^service_id} = page -> {:ok, page}
      _ -> {:error, :not_found}
    end
  end

  def fetch_booking_page(user, :resource, %CompanyResource{} = resource, page_id) do
    resource_id = resource.id

    case BookingPages.get_booking_page(user, page_id) do
      %BookingPage{resource_id: ^resource_id} = page -> {:ok, page}
      _ -> {:error, :not_found}
    end
  end

  def assign_booking_page_state(socket, user, :service, %CompanyService{} = service, default_auto_slot_days) do
    pages = BookingPages.list_booking_pages_for_service(user, service.id)

    socket
    |> assign(:booking_pages, pages)
    |> assign(:editing_booking_page_id, nil)
    |> assign(:booking_page_form, to_form(default_booking_page_changeset(user, :service, service, default_auto_slot_days), as: :booking_page))
  end

  def assign_booking_page_state(socket, user, :resource, %CompanyResource{} = resource, default_auto_slot_days) do
    pages = BookingPages.list_booking_pages_for_resource(user, resource.id)

    socket
    |> assign(:booking_pages, pages)
    |> assign(:editing_booking_page_id, nil)
    |> assign(:booking_page_form, to_form(default_booking_page_changeset(user, :resource, resource, default_auto_slot_days), as: :booking_page))
  end

  def default_booking_page_changeset(user, :service, %CompanyService{} = service, default_auto_slot_days) do
    BookingPages.change_booking_page(user, :service, service.id, nil, %{
      "title" => "#{service.name} Booking",
      "description" => service.description_text || "",
      "button_label" => "Book now",
      "slug" => booking_page_slug_seed(service.name, "service-booking-page"),
      "theme" => "brand",
      "is_published" => true,
      "auto_slots_enabled" => false,
      "schedule_start_date" => Date.add(Date.utc_today(), 1),
      "schedule_end_date" => Date.add(Date.utc_today(), default_auto_slot_days),
      "work_start_time" => ~T[09:00:00],
      "work_end_time" => ~T[18:00:00],
      "slot_minutes" => service.duration || 60,
      "break_minutes" => 10,
      "lunch_start_time" => nil,
      "lunch_end_time" => nil,
      "available_weekdays" => "mon,tue,wed,thu,fri",
      "excluded_dates" => "",
      "default_max_bookings" => nil
    })
  end

  def default_booking_page_changeset(user, :resource, %CompanyResource{} = resource, default_auto_slot_days) do
    BookingPages.change_booking_page(user, :resource, resource.id, nil, %{
      "title" => "#{resource.name} Booking",
      "description" => resource.description || "",
      "button_label" => "Book now",
      "slug" => booking_page_slug_seed(resource.name, "resource-booking-page"),
      "theme" => "brand",
      "is_published" => true,
      "auto_slots_enabled" => false,
      "schedule_start_date" => Date.add(Date.utc_today(), 1),
      "schedule_end_date" => Date.add(Date.utc_today(), default_auto_slot_days),
      "work_start_time" => ~T[09:00:00],
      "work_end_time" => ~T[18:00:00],
      "slot_minutes" => 60,
      "break_minutes" => 10,
      "lunch_start_time" => nil,
      "lunch_end_time" => nil,
      "available_weekdays" => "mon,tue,wed,thu,fri",
      "excluded_dates" => "",
      "default_max_bookings" => nil
    })
  end

  def booking_page_changeset_for_action(user, :service, %CompanyService{} = service, page_id, params) do
    case fetch_booking_page(user, :service, service, page_id) do
      {:ok, %BookingPage{} = page} ->
        BookingPages.change_booking_page(user, :service, service.id, page, params)

      _ ->
        BookingPages.change_booking_page(user, :service, service.id, nil, params)
    end
  end

  def booking_page_changeset_for_action(user, :resource, %CompanyResource{} = resource, page_id, params) do
    case fetch_booking_page(user, :resource, resource, page_id) do
      {:ok, %BookingPage{} = page} ->
        BookingPages.change_booking_page(user, :resource, resource.id, page, params)

      _ ->
        BookingPages.change_booking_page(user, :resource, resource.id, nil, params)
    end
  end

  defp list_target_slots(user, matcher) do
    slots =
      user
      |> SlotGeneration.list_company_slots()
      |> Enum.filter(matcher)
      |> Enum.sort_by(fn slot -> slot.start_time && DateTime.to_unix(slot.start_time) end, :asc)

    booking_counts = Bookings.confirmed_company_booking_counts_by_slot_ids(user, Enum.map(slots, & &1.id))

    Enum.map(slots, fn slot ->
      Map.put(slot, :booking_count, Map.get(booking_counts, slot.id, 0))
    end)
  end

  defp default_manual_slot_start do
    DateTime.utc_now()
    |> DateTime.truncate(:second)
    |> DateTime.add(24 * 60 * 60, :second)
  end

  defp default_manual_slot_end(start_time, %CompanyService{} = service, default_manual_slot_minutes) do
    duration_minutes =
      case service.duration do
        minutes when is_integer(minutes) and minutes > 0 -> minutes
        _ -> default_manual_slot_minutes
      end

    DateTime.add(start_time, duration_minutes * 60, :second)
  end

  defp auto_slot_config(changeset, weekday_to_number) do
    %{
      auto_slots_enabled: Ecto.Changeset.get_field(changeset, :auto_slots_enabled),
      start_date: Ecto.Changeset.get_field(changeset, :schedule_start_date),
      end_date: Ecto.Changeset.get_field(changeset, :schedule_end_date),
      work_start_time: Ecto.Changeset.get_field(changeset, :work_start_time),
      work_end_time: Ecto.Changeset.get_field(changeset, :work_end_time),
      slot_minutes: Ecto.Changeset.get_field(changeset, :slot_minutes),
      break_minutes: Ecto.Changeset.get_field(changeset, :break_minutes),
      lunch_start_time: Ecto.Changeset.get_field(changeset, :lunch_start_time),
      lunch_end_time: Ecto.Changeset.get_field(changeset, :lunch_end_time),
      weekdays: do_parse_weekdays(Ecto.Changeset.get_field(changeset, :available_weekdays), weekday_to_number),
      excluded_dates: parse_excluded_dates!(Ecto.Changeset.get_field(changeset, :excluded_dates)),
      max_bookings: Ecto.Changeset.get_field(changeset, :default_max_bookings)
    }
  end

  defp build_auto_slot_windows(config) do
    if config.auto_slots_enabled do
      config.start_date
      |> Date.range(config.end_date)
      |> Enum.flat_map(fn date ->
        if Date.day_of_week(date) in config.weekdays and not MapSet.member?(config.excluded_dates, date) do
          with {:ok, day_start} <- DateTime.new(date, config.work_start_time, "Etc/UTC"),
               {:ok, day_end} <- DateTime.new(date, config.work_end_time, "Etc/UTC") do
            build_auto_windows_for_day(
              day_start,
              day_end,
              lunch_range_for_day(date, config.lunch_start_time, config.lunch_end_time),
              config.slot_minutes,
              config.break_minutes,
              []
            )
          else
            _ -> []
          end
        else
          []
        end
      end)
    else
      []
    end
  end

  defp build_auto_windows_for_day(current, day_end, lunch_range, slot_minutes, break_minutes, acc) do
    slot_end = DateTime.add(current, slot_minutes * 60, :second)

    cond do
      DateTime.compare(current, day_end) != :lt ->
        Enum.reverse(acc)

      DateTime.after?(slot_end, day_end) ->
        Enum.reverse(acc)

      lunch_overlap?(lunch_range, current, slot_end) ->
        {_lunch_start, lunch_end} = lunch_range
        build_auto_windows_for_day(lunch_end, day_end, lunch_range, slot_minutes, break_minutes, acc)

      true ->
        next_start = DateTime.add(slot_end, break_minutes * 60, :second)

        build_auto_windows_for_day(
          next_start,
          day_end,
          lunch_range,
          slot_minutes,
          break_minutes,
          [%{start_time: current, end_time: slot_end} | acc]
        )
    end
  end

  defp lunch_range_for_day(_date, nil, nil), do: nil

  defp lunch_range_for_day(date, %Time{} = lunch_start_time, %Time{} = lunch_end_time) do
    with {:ok, lunch_start} <- DateTime.new(date, lunch_start_time, "Etc/UTC"),
         {:ok, lunch_end} <- DateTime.new(date, lunch_end_time, "Etc/UTC"),
         :gt <- DateTime.compare(lunch_end, lunch_start) do
      {lunch_start, lunch_end}
    else
      _ -> nil
    end
  end

  defp lunch_range_for_day(_date, _start_time, _end_time), do: nil

  defp lunch_overlap?(nil, _slot_start, _slot_end), do: false

  defp lunch_overlap?({lunch_start, lunch_end}, slot_start, slot_end) do
    DateTime.before?(slot_start, lunch_end) and DateTime.after?(slot_end, lunch_start)
  end

  defp do_parse_weekdays(value, weekday_to_number) when is_binary(value) do
    value
    |> String.split(",", trim: true)
    |> Enum.map(&(&1 |> String.trim() |> String.downcase()))
    |> Enum.reduce([], fn weekday, acc ->
      case Map.get(weekday_to_number, weekday) do
        nil -> acc
        day_number -> [day_number | acc]
      end
    end)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp do_parse_weekdays(_value, _weekday_to_number), do: []

  defp parse_excluded_dates!(value) do
    case do_parse_excluded_dates(value) do
      {:ok, dates} -> dates
      {:error, _reason} -> MapSet.new()
    end
  end

  defp do_parse_excluded_dates(nil), do: {:ok, MapSet.new()}
  defp do_parse_excluded_dates(""), do: {:ok, MapSet.new()}

  defp do_parse_excluded_dates(value) when is_binary(value) do
    value
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
    |> do_parse_excluded_dates()
  end

  defp do_parse_excluded_dates(values) when is_list(values) do
    values
    |> Enum.reduce_while(MapSet.new(), fn
      "", acc ->
        {:cont, acc}

      value, acc when is_binary(value) ->
        case Date.from_iso8601(String.trim(value)) do
          {:ok, date} -> {:cont, MapSet.put(acc, date)}
          _ -> {:halt, {:error, :invalid_date}}
        end

      _, _acc ->
        {:halt, {:error, :invalid_date}}
    end)
    |> case do
      {:error, _reason} = error -> error
      dates -> {:ok, dates}
    end
  end

  defp present?(value), do: value not in [nil, ""]
end
