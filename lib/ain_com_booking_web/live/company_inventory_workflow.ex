defmodule AinComBookingWeb.CompanyInventoryWorkflow do
  @moduledoc false

  import Phoenix.Component, only: [assign: 3, to_form: 2]
  import Phoenix.LiveView, only: [put_flash: 3, push_patch: 2]
  import AinComBookingWeb.CompanyConsoleComponents, only: [excluded_date_inputs_from_changeset: 1]
  import AinComBookingWeb.CompanyInventoryView

  alias AinComBooking.Bookings.CompanyBooking
  alias AinComBooking.Catalog.CompanyResource
  alias AinComBooking.Catalog.CompanyService
  alias AinComBooking.CompanyConsole.BookingPage
  alias AinComBooking.CompanyConsole.BookingPages
  alias AinComBooking.CompanyConsole.Bookings
  alias AinComBookingWeb.CompanyInventoryState
  alias AinComBookingWeb.CompanyInventoryTarget

  def validate_inventory(socket, params) do
    changeset =
      socket
      |> CompanyInventoryTarget.inventory_changeset_for_action(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset, as: inventory_form_as(socket.assigns.inventory_type)))}
  end

  def save_inventory(socket, params) do
    case socket.assigns.live_action do
      :new ->
        case CompanyInventoryTarget.create_inventory_item(socket.assigns.current_user, socket.assigns.inventory_type, params) do
          {:ok, inventory} ->
            {:noreply,
             socket
             |> put_flash(:info, inventory_created_message(socket.assigns.inventory_type))
             |> push_patch(to: inventory_show_path(socket.assigns.inventory_type, inventory.id))}

          {:error, changeset} ->
            {:noreply, assign(socket, :form, to_form(Map.put(changeset, :action, :insert), as: inventory_form_as(socket.assigns.inventory_type)))}
        end

      :edit ->
        case CompanyInventoryTarget.update_inventory_item(socket.assigns.inventory_type, socket.assigns.service, params) do
          {:ok, inventory} ->
            {:noreply,
             socket
             |> put_flash(:info, inventory_updated_message(socket.assigns.inventory_type))
             |> push_patch(to: inventory_show_path(socket.assigns.inventory_type, inventory.id))}

          {:error, changeset} ->
            {:noreply, assign(socket, :form, to_form(Map.put(changeset, :action, :update), as: inventory_form_as(socket.assigns.inventory_type)))}
        end
    end
  end

  def validate_booking_page(socket, params) do
    changeset =
      CompanyInventoryTarget.booking_page_changeset_for_action(
        socket.assigns.current_user,
        socket.assigns.inventory_type,
        socket.assigns.service,
        socket.assigns.editing_booking_page_id,
        params
      )
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :booking_page_form, to_form(changeset, as: :booking_page))}
  end

  def save_booking_page(socket, params, default_auto_slot_days) do
    result =
      case CompanyInventoryTarget.fetch_booking_page(
             socket.assigns.current_user,
             socket.assigns.inventory_type,
             socket.assigns.service,
             socket.assigns.editing_booking_page_id
           ) do
        {:ok, %BookingPage{} = page} ->
          BookingPages.update_booking_page(page, params)

        _ ->
          CompanyInventoryTarget.create_booking_page_for_inventory(
            socket.assigns.current_user,
            socket.assigns.inventory_type,
            socket.assigns.service.id,
            params
          )
      end

    case result do
      {:ok, _page} ->
        {:noreply,
         socket
         |> assign_inventory_booking_page_state(default_auto_slot_days)
         |> put_flash(:info, "Booking page saved.")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :booking_page_form, to_form(Map.put(changeset, :action, :insert), as: :booking_page))}

      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, "Booking page could not be found.")}
    end
  end

  def edit_booking_page(socket, page_id) do
    case CompanyInventoryTarget.fetch_booking_page(socket.assigns.current_user, socket.assigns.inventory_type, socket.assigns.service, page_id) do
      {:ok, %BookingPage{} = page} ->
        {:noreply,
         socket
         |> assign(:editing_booking_page_id, page.id)
         |> assign(
           :booking_page_form,
           to_form(
             BookingPages.change_booking_page(
               socket.assigns.current_user,
               socket.assigns.inventory_type,
               socket.assigns.service.id,
               page
             ),
             as: :booking_page
           )
         )}

      _ ->
        {:noreply, put_flash(socket, :error, "Booking page could not be found.")}
    end
  end

  def cancel_booking_page_edit(socket, default_auto_slot_days) do
    {:noreply, assign_inventory_booking_page_state(socket, default_auto_slot_days)}
  end

  def delete_booking_page(socket, page_id, default_auto_slot_days) do
    case CompanyInventoryTarget.fetch_booking_page(socket.assigns.current_user, socket.assigns.inventory_type, socket.assigns.service, page_id) do
      {:ok, %BookingPage{} = page} ->
        case BookingPages.delete_booking_page(page) do
          {:ok, _page} ->
            {:noreply,
             socket
             |> assign_inventory_booking_page_state(default_auto_slot_days)
             |> put_flash(:info, "Booking page deleted.")}

          {:error, _reason} ->
            {:noreply, put_flash(socket, :error, "Booking page could not be deleted.")}
        end

      _ ->
        {:noreply, put_flash(socket, :error, "Booking page could not be found.")}
    end
  end

  def edit_booking(socket, booking_id) do
    case fetch_inventory_booking(socket, booking_id) do
      {:ok, booking} ->
        {:noreply,
         socket
         |> assign(:editing_booking_id, booking.id)
         |> assign(:booking_edit_form, to_form(Bookings.change_company_booking(booking), as: :booking))}

      _ ->
        {:noreply, put_flash(socket, :error, "예약을 찾을 수 없습니다.")}
    end
  end

  def cancel_booking(socket, booking_id) do
    with {:ok, booking} <- fetch_inventory_booking(socket, booking_id),
         {:ok, _updated_booking} <- Bookings.update_company_booking(socket.assigns.current_user, booking, %{"status" => "cancelled"}) do
      {:noreply,
       socket
       |> refresh_inventory_bookings_modal()
       |> maybe_refresh_inventory_slot_calendar()
       |> put_flash(:info, "예약을 취소했습니다.")}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         socket
         |> assign(:editing_booking_id, booking_id)
         |> assign(:booking_edit_form, to_form(Map.put(changeset, :action, :update), as: :booking))
         |> put_flash(:error, "예약 취소에 실패했습니다.")}

      _ ->
        {:noreply, put_flash(socket, :error, "예약을 찾을 수 없습니다.")}
    end
  end

  def validate_booking(socket, booking_id, params) do
    case fetch_inventory_booking(socket, booking_id) do
      {:ok, booking} ->
        changeset =
          booking
          |> Bookings.change_company_booking(params)
          |> Map.put(:action, :validate)

        {:noreply,
         socket
         |> assign(:editing_booking_id, booking.id)
         |> assign(:booking_edit_form, to_form(changeset, as: :booking))}

      _ ->
        {:noreply, put_flash(socket, :error, "예약을 찾을 수 없습니다.")}
    end
  end

  def save_booking(socket, booking_id, params) do
    case fetch_inventory_booking(socket, booking_id) do
      {:ok, booking} ->
        case Bookings.update_company_booking(socket.assigns.current_user, booking, params) do
          {:ok, _updated_booking} ->
            {:noreply,
             socket
             |> refresh_inventory_bookings_modal()
             |> maybe_refresh_inventory_slot_calendar()
             |> assign(:editing_booking_id, nil)
             |> assign(:booking_edit_form, nil)
             |> put_flash(:info, "예약 정보를 수정했습니다.")}

          {:error, %Ecto.Changeset{} = changeset} ->
            {:noreply,
             socket
             |> assign(:editing_booking_id, booking.id)
             |> assign(:booking_edit_form, to_form(Map.put(changeset, :action, :update), as: :booking))}

          _ ->
            {:noreply, put_flash(socket, :error, "예약 수정에 실패했습니다.")}
        end

      _ ->
        {:noreply, put_flash(socket, :error, "예약을 찾을 수 없습니다.")}
    end
  end

  def open_inventory_bookings_modal(socket, service_id) do
    case CompanyInventoryTarget.get_inventory_item(socket.assigns.current_user, socket.assigns.inventory_type, service_id) do
      %CompanyService{} = service ->
        {:noreply, do_open_inventory_bookings_modal(socket, service)}

      %CompanyResource{} = service ->
        {:noreply, do_open_inventory_bookings_modal(socket, service)}

      _ ->
        {:noreply, put_flash(socket, :error, inventory_not_found_message(socket.assigns.inventory_type))}
    end
  end

  def confirm_delete(socket) do
    case CompanyInventoryTarget.delete_inventory_item(socket.assigns.inventory_type, socket.assigns.service) do
      {:ok, _service} ->
        {:noreply,
         socket
         |> put_flash(:info, inventory_deleted_message(socket.assigns.inventory_type))
         |> push_patch(to: inventory_index_path(socket.assigns.inventory_type))}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, inventory_delete_error_message(socket.assigns.inventory_type))}
    end
  end

  def load_inventory(socket, id, action, default_auto_slot_days, default_auto_slot_changeset_fun) do
    case CompanyInventoryTarget.get_inventory_item(socket.assigns.current_user, socket.assigns.inventory_type, id) do
      nil ->
        {:noreply,
         socket
         |> put_flash(:error, inventory_missing_message(socket.assigns.inventory_type))
         |> push_patch(to: inventory_index_path(socket.assigns.inventory_type))}

      service ->
        socket =
          socket
          |> assign(:service, service)
          |> assign(:page_title, inventory_item_page_title(socket.assigns.inventory_type, action, service))
          |> assign(:form, CompanyInventoryTarget.form_for_action(socket.assigns.current_user, action, service))

        socket =
          if action == :show do
            auto_changeset = default_auto_slot_changeset_fun.()

            socket
            |> assign(:auto_slot_form, to_form(auto_changeset, as: :auto_slot))
            |> assign(:auto_excluded_date_inputs, excluded_date_inputs_from_changeset(auto_changeset))
            |> assign(:show_manual_slot_modal, false)
            |> assign(:show_auto_slot_modal, false)
            |> assign_inventory_slot_state(service)
            |> assign_inventory_booking_page_state(default_auto_slot_days)
            |> CompanyInventoryState.reset_manual_slot_state()
          else
            CompanyInventoryState.clear_slot_state(socket, :service_slots, :bookings_modal_inventory_id, :bookings_modal_inventory_name)
          end

        {:noreply, socket}
    end
  end

  defp do_open_inventory_bookings_modal(socket, service) do
    socket
    |> CompanyInventoryState.open_bookings_modal(
      :bookings_modal_inventory_id,
      :bookings_modal_inventory_name,
      service.id,
      service.name,
      CompanyInventoryTarget.list_inventory_bookings(socket.assigns.current_user, socket.assigns.inventory_type, service.id)
    )
  end

  defp fetch_inventory_booking(socket, booking_id) do
    service_id = socket.assigns.bookings_modal_inventory_id

    case Bookings.get_company_booking(socket.assigns.current_user, booking_id) do
      %CompanyBooking{} = booking when socket.assigns.inventory_type == :service and booking.service_id == service_id -> {:ok, booking}
      %CompanyBooking{} = booking when socket.assigns.inventory_type == :resource and booking.resource_id == service_id -> {:ok, booking}
      _ -> {:error, :not_found}
    end
  end

  defp refresh_inventory_bookings_modal(socket) do
    case socket.assigns.bookings_modal_inventory_id do
      service_id when is_binary(service_id) ->
        assign(
          socket,
          :bookings_modal_bookings,
          CompanyInventoryTarget.list_inventory_bookings(socket.assigns.current_user, socket.assigns.inventory_type, service_id)
        )

      _ ->
        socket
    end
  end

  defp maybe_refresh_inventory_slot_calendar(socket) do
    if socket.assigns.live_action == :show and
         not is_nil(socket.assigns.service) and
         socket.assigns.service.id == socket.assigns.bookings_modal_inventory_id do
      assign_inventory_slot_state(socket, socket.assigns.service)
    else
      socket
    end
  end

  defp assign_inventory_slot_state(socket, service) do
    assign_inventory_slot_state(socket, service, [])
  end

  defp assign_inventory_slot_state(socket, service, opts) do
    slots = CompanyInventoryTarget.list_slots(socket.assigns.current_user, socket.assigns.inventory_type, service.id)
    CompanyInventoryState.put_slot_calendar(socket, :service_slots, slots, opts)
  end

  defp assign_inventory_booking_page_state(socket, default_auto_slot_days) do
    CompanyInventoryTarget.assign_booking_page_state(
      socket,
      socket.assigns.current_user,
      socket.assigns.inventory_type,
      socket.assigns.service,
      default_auto_slot_days
    )
  end
end
