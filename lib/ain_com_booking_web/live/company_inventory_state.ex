defmodule AinComBookingWeb.CompanyInventoryState do
  @moduledoc false

  import Phoenix.Component, only: [assign: 3]

  import AinComBookingWeb.CompanyConsoleComponents,
    only: [
      empty_calendar_month: 0,
      build_calendar_month: 3,
      slots_for_date: 2,
      resolve_selected_date: 2,
      resolve_visible_month: 2
    ]

  def put_slot_calendar(socket, slot_assign_key, slots, opts \\ []) do
    selected_date =
      resolve_selected_date(slots, Keyword.get(opts, :selected_date, socket.assigns.selected_calendar_date))

    visible_month =
      resolve_visible_month(selected_date, Keyword.get(opts, :visible_month, socket.assigns.visible_calendar_month))

    socket
    |> assign(slot_assign_key, slots)
    |> assign(:selected_calendar_date, selected_date)
    |> assign(:visible_calendar_month, visible_month)
    |> assign(:calendar_month, build_calendar_month(slots, visible_month, selected_date))
    |> assign(:selected_calendar_slots, slots_for_date(slots, selected_date))
  end

  def reset_manual_slot_state(socket, selected_date \\ nil) do
    selected_date = selected_date || socket.assigns.selected_calendar_date || Date.utc_today()

    socket
    |> assign(:manual_slot_date, selected_date)
    |> assign(:manual_selected_ranges, [])
    |> assign(:manual_slot_max_bookings, "")
    |> assign(:manual_slot_error, nil)
  end

  def clear_slot_state(socket, slot_assign_key, bookings_modal_id_key, bookings_modal_name_key) do
    socket
    |> assign(slot_assign_key, [])
    |> assign(:calendar_month, empty_calendar_month())
    |> assign(:selected_calendar_date, nil)
    |> assign(:visible_calendar_month, nil)
    |> assign(:selected_calendar_slots, [])
    |> assign(:show_manual_slot_modal, false)
    |> assign(:show_auto_slot_modal, false)
    |> assign(:manual_slot_date, nil)
    |> assign(:manual_selected_ranges, [])
    |> assign(:manual_slot_max_bookings, "")
    |> assign(:manual_slot_error, nil)
    |> assign(:auto_slot_form, nil)
    |> assign(:auto_excluded_date_inputs, [""])
    |> assign(:show_bookings_modal, false)
    |> assign(bookings_modal_id_key, nil)
    |> assign(bookings_modal_name_key, nil)
    |> assign(:bookings_modal_bookings, [])
    |> assign(:editing_booking_id, nil)
    |> assign(:booking_edit_form, nil)
  end

  def open_manual_slot_modal(socket) do
    selected_date = socket.assigns.selected_calendar_date || Date.utc_today()

    socket
    |> assign(:manual_slot_date, selected_date)
    |> assign(:manual_selected_ranges, [])
    |> assign(:manual_slot_max_bookings, "")
    |> assign(:manual_slot_error, nil)
    |> assign(:show_manual_slot_modal, true)
  end

  def close_manual_slot_modal(socket) do
    socket
    |> assign(:show_manual_slot_modal, false)
    |> assign(:manual_slot_error, nil)
  end

  def assign_manual_slot_state(socket, selected_date, selected_ranges, max_bookings, error \\ nil) do
    socket
    |> assign(:manual_slot_date, selected_date)
    |> assign(:manual_selected_ranges, selected_ranges)
    |> assign(:manual_slot_max_bookings, max_bookings)
    |> assign(:manual_slot_error, error)
  end

  def open_auto_slot_modal(socket, form, excluded_date_inputs) do
    socket
    |> assign(:auto_slot_form, form)
    |> assign(:auto_excluded_date_inputs, excluded_date_inputs)
    |> assign(:show_auto_slot_modal, true)
  end

  def close_auto_slot_modal(socket), do: assign(socket, :show_auto_slot_modal, false)

  def assign_auto_slot_form(socket, form, excluded_date_inputs) do
    socket
    |> assign(:auto_slot_form, form)
    |> assign(:auto_excluded_date_inputs, excluded_date_inputs)
  end

  def open_bookings_modal(socket, bookings_modal_id_key, bookings_modal_name_key, target_id, target_name, bookings) do
    socket
    |> assign(:show_bookings_modal, true)
    |> assign(bookings_modal_id_key, target_id)
    |> assign(bookings_modal_name_key, target_name)
    |> assign(:bookings_modal_bookings, bookings)
    |> assign(:editing_booking_id, nil)
    |> assign(:booking_edit_form, nil)
  end

  def close_bookings_modal(socket) do
    socket
    |> assign(:show_bookings_modal, false)
    |> assign(:editing_booking_id, nil)
    |> assign(:booking_edit_form, nil)
  end
end
