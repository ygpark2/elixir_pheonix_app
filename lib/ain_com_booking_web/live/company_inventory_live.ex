defmodule AinComBookingWeb.CompanyInventoryLive do
  @moduledoc false
  use AinComBookingWeb, :live_view

  import AinComBookingWeb.CompanyConsoleComponents
  import AinComBookingWeb.CompanyInventoryComponents
  import AinComBookingWeb.CompanyInventoryView

  alias AinComBooking.CompanyConsole
  alias AinComBookingWeb.CompanyInventorySlotWorkflow
  alias AinComBookingWeb.CompanyInventoryState
  alias AinComBookingWeb.CompanyInventoryTarget
  alias AinComBookingWeb.CompanyInventoryWorkflow

  @resource_type_options [
    {"Room", "room"},
    {"Equipment", "equipment"},
    {"Desk", "desk"},
    {"Studio", "studio"}
  ]
  @default_manual_slot_minutes 30
  @default_auto_slot_days 7
  @weekday_to_number %{
    "mon" => 1,
    "tue" => 2,
    "wed" => 3,
    "thu" => 4,
    "fri" => 5,
    "sat" => 6,
    "sun" => 7
  }
  @booking_status_options [
    {"Confirmed", "confirmed"},
    {"Cancelled", "cancelled"},
    {"No-show", "noshow"}
  ]

  def render(assigns) do
    ~H"""
    <.shell
      current_user={@current_user}
      company={@company}
      active_section={inventory_section(@inventory_type)}
      page_title={@page_title}
      page_label={inventory_page_label(@live_action)}
      page_subtitle={inventory_page_subtitle(@inventory_type)}
    >
      <div class="space-y-5">
        <div :if={@live_action == :index} class="flex justify-end">
          <.link
            patch={inventory_new_path(@inventory_type)}
            class="inline-flex items-center gap-2 rounded-full bg-brand-600 px-4 py-2 text-sm font-semibold text-white transition hover:bg-brand-500"
          >
            <.icon name="hero-plus" class="h-4 w-4" />
            <span><%= inventory_new_label(@inventory_type) %></span>
          </.link>
        </div>

        <section :if={@live_action == :index} class="space-y-4">
          <div :if={@services == []} class="rounded-3xl border border-dashed border-slate-300 bg-slate-50 px-6 py-10 text-center text-sm text-slate-500">
            <%= inventory_empty_state(@inventory_type) %>
          </div>

          <.inventory_card :for={service <- @services} inventory_type={@inventory_type} inventory={service} />
        </section>

        <section :if={@live_action == :new or @live_action == :edit} class="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
          <.simple_form for={@form} as={inventory_form_as(@inventory_type)} id={inventory_form_id(@inventory_type)} phx-change="validate" phx-submit="save">
            <div class="grid gap-4 md:grid-cols-2">
              <.input field={@form[:name]} type="text" label="Name" />
              <.input :if={resource_inventory?(@inventory_type)} field={@form[:type]} type="select" label="Type" options={@resource_type_options} prompt="Choose a type" />
              <.input :if={resource_inventory?(@inventory_type)} field={@form[:location]} type="text" label="Location" />
              <.input field={@form[:currency]} type="text" label="Currency" />
              <.input :if={service_inventory?(@inventory_type)} field={@form[:duration]} type="number" label="Duration (minutes)" min="1" />
              <.input field={@form[:price]} type="number" label="Price" step="0.01" min="0" />
            </div>

            <.input :if={service_inventory?(@inventory_type)} field={@form[:description_text]} type="textarea" rows="4" label="Description" />
            <.input :if={resource_inventory?(@inventory_type)} field={@form[:description]} type="textarea" rows="4" label="Description" />

            <div :if={service_inventory?(@inventory_type)} class="grid gap-3 md:grid-cols-2">
              <.input field={@form[:is_active]} type="checkbox" label="Active" />
              <.input field={@form[:is_public]} type="checkbox" label="Public" />
              <.input field={@form[:is_recurring]} type="checkbox" label="Recurring" />
              <.input field={@form[:hide_duration]} type="checkbox" label="Hide duration" />
            </div>

            <:actions>
              <.button type="submit" phx-disable-with="Saving..." class="rounded-full bg-brand-600 px-5 hover:bg-brand-500">
                <%= inventory_submit_label(@inventory_type, @live_action) %>
              </.button>
              <.link patch={inventory_cancel_path(@inventory_type, @service)} class="rounded-full px-4 py-2 text-sm font-medium text-slate-500 transition hover:bg-slate-100 hover:text-slate-900">
                Cancel
              </.link>
            </:actions>
          </.simple_form>
        </section>

        <section :if={@live_action == :show and @service} class="space-y-4">
          <.inventory_detail_header inventory_type={@inventory_type} inventory={@service} />

          <.booking_page_section
            inventory_type={@inventory_type}
            booking_pages={@booking_pages}
            booking_page_form={@booking_page_form}
            editing_booking_page_id={@editing_booking_page_id}
          />

          <.slot_calendar_section
            inventory_type={@inventory_type}
            calendar_month={@calendar_month}
            selected_calendar_date={@selected_calendar_date}
            selected_calendar_slots={@selected_calendar_slots}
          />

          <.auto_slot_modal
            inventory_type={@inventory_type}
            show_auto_slot_modal={@show_auto_slot_modal}
            auto_slot_form={@auto_slot_form}
            auto_excluded_date_inputs={@auto_excluded_date_inputs}
            company={@company}
          />

          <.manual_slot_modal
            inventory_type={@inventory_type}
            show_manual_slot_modal={@show_manual_slot_modal}
            service_slots={@service_slots}
            manual_slot_date={@manual_slot_date}
            manual_slot_max_bookings={@manual_slot_max_bookings}
            manual_selected_ranges={@manual_selected_ranges}
            manual_slot_error={@manual_slot_error}
          />
        </section>

        <section :if={@live_action == :delete and @service} class="rounded-3xl border border-danger-200 bg-danger-25 p-6 shadow-sm">
          <p class="text-xs font-semibold uppercase tracking-[0.18em] text-danger-700"><%= inventory_delete_heading(@inventory_type) %></p>
          <h2 class="mt-2 text-2xl font-semibold tracking-tight text-slate-950"><%= @service.name %></h2>
          <p class="mt-3 text-sm leading-6 text-slate-600">
            <%= inventory_delete_description(@inventory_type) %>
          </p>

          <div class="mt-5 flex flex-wrap items-center gap-3">
            <button
              type="button"
              phx-click="confirm_delete"
              class="inline-flex items-center gap-2 rounded-full bg-danger-600 px-5 py-2 text-sm font-semibold text-white transition hover:bg-danger-500"
            >
              <.icon name="hero-trash" class="h-4 w-4" />
              <span><%= inventory_delete_button_label(@inventory_type) %></span>
            </button>
            <.link patch={inventory_show_path(@inventory_type, @service.id)} class="rounded-full px-4 py-2 text-sm font-medium text-slate-500 transition hover:bg-white hover:text-slate-900">
              Cancel
            </.link>
          </div>
        </section>
      </div>

      <.bookings_modal
        inventory_type={@inventory_type}
        show_bookings_modal={@show_bookings_modal}
        bookings_modal_inventory_name={@bookings_modal_inventory_name}
        bookings_modal_bookings={@bookings_modal_bookings}
        editing_booking_id={@editing_booking_id}
        booking_edit_form={@booking_edit_form}
        booking_status_options={booking_status_options()}
      />

      <:sidebar>
        <div class="space-y-4">
          <.inventory_snapshot inventory_type={@inventory_type} stats={@stats} />
        </div>
      </:sidebar>
    </.shell>
    """
  end

  def mount(_params, _session, socket) do
    company = CompanyConsole.ensure_company!(socket.assigns.current_user)
    inventory_type = :service

    {:ok,
     socket
     |> assign(:hide_global_user_menu, true)
     |> assign(:company, company)
     |> assign(:inventory_type, inventory_type)
     |> assign(:resource_type_options, @resource_type_options)
     |> assign(:service, nil)
     |> assign(:form, nil)
     |> assign(:services, [])
     |> assign(:booking_pages, [])
     |> assign(:booking_page_form, nil)
     |> assign(:editing_booking_page_id, nil)
     |> assign(:stats, %{})
     |> assign(:page_title, inventory_page_title(inventory_type))
     |> CompanyInventoryState.clear_slot_state(:service_slots, :bookings_modal_inventory_id, :bookings_modal_inventory_name)}
  end

  def handle_params(params, uri, socket) do
    inventory_type = inventory_type_from_uri(uri)
    services = CompanyInventoryTarget.list_inventory_items(socket.assigns.current_user, inventory_type)

    socket =
      socket
      |> assign(:inventory_type, inventory_type)
      |> assign(:services, services)
      |> assign(:stats, CompanyInventoryTarget.inventory_stats(inventory_type, services))

    case socket.assigns.live_action do
      :index ->
        {:noreply,
         socket
         |> assign(:page_title, inventory_page_title(socket.assigns.inventory_type))
         |> assign(:service, nil)
         |> assign(:form, nil)
         |> clear_slot_state()}

      :new ->
        {:noreply,
         socket
         |> assign(:page_title, inventory_create_page_title(socket.assigns.inventory_type))
         |> assign(:service, nil)
         |> assign(
           :form,
           to_form(CompanyInventoryTarget.default_inventory_changeset(socket.assigns.current_user, socket.assigns.inventory_type),
             as: inventory_form_as(socket.assigns.inventory_type)
           )
         )
         |> clear_slot_state()}

      action ->
        CompanyInventoryWorkflow.load_inventory(socket, params["id"], action, @default_auto_slot_days, fn ->
          CompanyInventorySlotWorkflow.default_auto_slot_changeset(@default_auto_slot_days, @weekday_to_number)
        end)
    end
  end

  def handle_event("validate", params, socket) do
    params = Map.get(params, inventory_form_param(socket.assigns.inventory_type), %{})
    CompanyInventoryWorkflow.validate_inventory(socket, params)
  end

  def handle_event("save", params, socket) do
    params = Map.get(params, inventory_form_param(socket.assigns.inventory_type), %{})
    CompanyInventoryWorkflow.save_inventory(socket, params)
  end

  def handle_event("validate_booking_page", %{"booking_page" => params}, socket) do
    CompanyInventoryWorkflow.validate_booking_page(socket, normalize_booking_page_params(params))
  end

  def handle_event("save_booking_page", %{"booking_page" => params}, socket) do
    CompanyInventoryWorkflow.save_booking_page(socket, normalize_booking_page_params(params), @default_auto_slot_days)
  end

  def handle_event("edit_booking_page", %{"page_id" => page_id}, socket) do
    CompanyInventoryWorkflow.edit_booking_page(socket, page_id)
  end

  def handle_event("cancel_booking_page_edit", _params, socket) do
    CompanyInventoryWorkflow.cancel_booking_page_edit(socket, @default_auto_slot_days)
  end

  def handle_event("delete_booking_page", %{"page_id" => page_id}, socket) do
    CompanyInventoryWorkflow.delete_booking_page(socket, page_id, @default_auto_slot_days)
  end

  def handle_event("open_service_bookings_modal", %{"service_id" => service_id}, socket) do
    CompanyInventoryWorkflow.open_inventory_bookings_modal(socket, service_id)
  end

  def handle_event("open_resource_bookings_modal", %{"resource_id" => resource_id}, socket) do
    CompanyInventoryWorkflow.open_inventory_bookings_modal(socket, resource_id)
  end

  def handle_event("close_bookings_modal", _params, socket) do
    {:noreply, CompanyInventoryState.close_bookings_modal(socket)}
  end

  def handle_event("edit_booking", %{"booking_id" => booking_id}, socket) do
    CompanyInventoryWorkflow.edit_booking(socket, booking_id)
  end

  def handle_event("cancel_booking_edit", _params, socket) do
    {:noreply,
     socket
     |> assign(:editing_booking_id, nil)
     |> assign(:booking_edit_form, nil)}
  end

  def handle_event("cancel_booking", %{"booking_id" => booking_id}, socket) do
    CompanyInventoryWorkflow.cancel_booking(socket, booking_id)
  end

  def handle_event("validate_booking", %{"booking_id" => booking_id, "booking" => params}, socket) do
    CompanyInventoryWorkflow.validate_booking(socket, booking_id, params)
  end

  def handle_event("save_booking", %{"booking_id" => booking_id, "booking" => params}, socket) do
    CompanyInventoryWorkflow.save_booking(socket, booking_id, params)
  end

  def handle_event("open_manual_slot_modal", _params, socket) do
    CompanyInventorySlotWorkflow.open_manual_slot_modal(socket)
  end

  def handle_event("close_manual_slot_modal", _params, socket) do
    CompanyInventorySlotWorkflow.close_manual_slot_modal(socket)
  end

  def handle_event("manual_drag_select", %{"start_index" => start_index, "end_index" => end_index}, socket) do
    CompanyInventorySlotWorkflow.manual_drag_select(socket, start_index, end_index)
  end

  def handle_event("clear_manual_drag_ranges", _params, socket) do
    CompanyInventorySlotWorkflow.clear_manual_drag_ranges(socket)
  end

  def handle_event("remove_manual_drag_range", %{"index" => index}, socket) do
    CompanyInventorySlotWorkflow.remove_manual_drag_range(socket, index)
  end

  def handle_event("validate_manual_slot", %{"manual_slot" => params}, socket) do
    CompanyInventorySlotWorkflow.validate_manual_slot(socket, params)
  end

  def handle_event("create_manual_slot", %{"manual_slot" => params}, socket) do
    CompanyInventorySlotWorkflow.create_manual_slot(socket, params, @default_manual_slot_minutes)
  end

  def handle_event("open_auto_slot_modal", _params, socket) do
    CompanyInventorySlotWorkflow.open_auto_slot_modal(socket, @default_auto_slot_days, @weekday_to_number)
  end

  def handle_event("close_auto_slot_modal", _params, socket) do
    CompanyInventorySlotWorkflow.close_auto_slot_modal(socket)
  end

  def handle_event("validate_auto_slot", %{"auto_slot" => params}, socket) do
    CompanyInventorySlotWorkflow.validate_auto_slot(socket, params, @weekday_to_number)
  end

  def handle_event("create_auto_slots", %{"auto_slot" => params}, socket) do
    CompanyInventorySlotWorkflow.create_auto_slots(socket, params, @default_auto_slot_days, @weekday_to_number)
  end

  def handle_event("add_auto_excluded_date", _params, socket) do
    CompanyInventorySlotWorkflow.add_auto_excluded_date(socket)
  end

  def handle_event("remove_auto_excluded_date", %{"index" => index}, socket) do
    CompanyInventorySlotWorkflow.remove_auto_excluded_date(socket, index)
  end

  def handle_event("select_calendar_date", %{"date" => selected_date}, socket) do
    CompanyInventorySlotWorkflow.select_calendar_date(socket, selected_date)
  end

  def handle_event("prev_calendar_month", _params, socket) do
    CompanyInventorySlotWorkflow.prev_calendar_month(socket)
  end

  def handle_event("next_calendar_month", _params, socket) do
    CompanyInventorySlotWorkflow.next_calendar_month(socket)
  end

  def handle_event("confirm_delete", _params, socket) do
    CompanyInventoryWorkflow.confirm_delete(socket)
  end

  defp clear_slot_state(socket) do
    CompanyInventoryState.clear_slot_state(socket, :service_slots, :bookings_modal_inventory_id, :bookings_modal_inventory_name)
  end

  defp booking_status_options, do: @booking_status_options
end
