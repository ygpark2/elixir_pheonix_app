defmodule AinComBookingWeb.CompanySlotLive do
  @moduledoc false
  use AinComBookingWeb, :live_view

  import AinComBookingWeb.CompanyConsoleComponents

  alias AinComBooking.Bookings.CompanySlot
  alias AinComBooking.CompanyConsole

  @status_options [
    {"Available", "available"},
    {"Booked", "booked"},
    {"Cancelled", "cancelled"}
  ]

  @default_slot_minutes 30

  def render(assigns) do
    ~H"""
    <.shell
      current_user={@current_user}
      company={@company}
      active_section={:slots}
      page_title={@page_title}
      page_label={slot_page_label(@live_action)}
      page_subtitle="Only future company slots marked as `available` are shown to customers on published booking URLs."
    >
      <div class="space-y-5">
        <div :if={@live_action == :index} class="flex justify-end">
          <.link
            patch={~p"/company/console/slots/new"}
            class="inline-flex items-center gap-2 rounded-full bg-brand-600 px-4 py-2 text-sm font-semibold text-white transition hover:bg-brand-500"
          >
            <.icon name="hero-plus" class="h-4 w-4" />
            <span>New Slot</span>
          </.link>
        </div>

        <section :if={@live_action == :index} class="space-y-4">
          <div :if={@slots == []} class="rounded-3xl border border-dashed border-slate-300 bg-slate-50 px-6 py-10 text-center text-sm text-slate-500">
            No company slots yet. Add future availability so customer pages can accept reservations.
          </div>

          <article
            :for={slot <- @slots}
            id={"company-slot-#{slot.id}"}
            class="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm"
          >
            <div class="flex flex-wrap items-start justify-between gap-4">
              <div class="min-w-0 flex-1">
              <div class="flex flex-wrap items-center gap-2">
                <h2 class="text-lg font-semibold tracking-tight text-slate-950"><%= slot_target_title(slot) %></h2>
                <span class={status_badge_class(slot.status)}><%= slot_status_label(slot.status) %></span>
                <span :if={slot_visible_publicly?(slot)} class="rounded-full bg-brand-50 px-2.5 py-1 text-[11px] font-semibold text-brand-700">
                  Publishable now
                </span>
                <span :if={slot.booking_page} class="rounded-full bg-slate-100 px-2.5 py-1 text-[11px] font-semibold text-slate-600">
                  <%= slot.booking_page.title %>
                </span>
              </div>
              <p class="mt-2 text-sm leading-6 text-slate-600"><%= slot_time_range(slot) %></p>
              <p class="mt-2 text-xs font-medium uppercase tracking-[0.16em] text-slate-400">
                <%= slot_capacity_label(slot) %>
              </p>
            </div>

              <div class="flex flex-wrap items-center gap-2">
                <.link patch={~p"/company/console/slots/#{slot.id}"} class={action_link_class()}>View</.link>
                <.link patch={~p"/company/console/slots/#{slot.id}/edit"} class={action_link_class()}>Edit</.link>
                <.link patch={~p"/company/console/slots/#{slot.id}/delete"} class={danger_action_link_class()}>Delete</.link>
              </div>
            </div>
          </article>
        </section>

        <section :if={@live_action == :new or @live_action == :edit} class="space-y-4">
          <div :if={!@has_targets} class="rounded-3xl border border-dashed border-warning-300 bg-warning-50 px-5 py-4 text-sm leading-6 text-warning-900">
            Create a company service or resource first. Slots must attach to a bookable target.
          </div>

          <div class="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
            <.simple_form for={@form} as={:slot} id="company-slot-form" phx-change="validate" phx-submit="save">
              <div class="grid gap-4 md:grid-cols-2">
                <.input field={@form[:start_time]} type="datetime-local" label="Start time (UTC)" />
                <.input field={@form[:end_time]} type="datetime-local" label="End time (UTC)" />
                <.input field={@form[:status]} type="select" label="Status" options={@status_options} />
                <.input field={@form[:booking_page_id]} type="select" label="Booking Page" options={@booking_page_options} prompt="Optional" />
                <.input field={@form[:service_id]} type="select" label="Service" options={@service_options} prompt="Optional" />
                <.input field={@form[:resource_id]} type="select" label="Resource" options={@resource_options} prompt="Optional" />
                <.input field={@form[:max_bookings]} type="number" label="Max Bookings" min="1" />
              </div>

              <p class="mt-3 text-xs leading-6 text-slate-500">
                Leave `Max Bookings` blank to accept unlimited reservations for this exact time block. If you select a booking page, its service/resource target is applied automatically.
              </p>

              <:actions>
                <.button
                  type="submit"
                  disabled={!@has_targets}
                  phx-disable-with="Saving..."
                  class="rounded-full bg-brand-600 px-5 hover:bg-brand-500"
                >
                  <%= if @live_action == :new, do: "Create Slot", else: "Save Changes" %>
                </.button>
                <.link patch={cancel_slot_path(@slot)} class="rounded-full px-4 py-2 text-sm font-medium text-slate-500 transition hover:bg-slate-100 hover:text-slate-900">
                  Cancel
                </.link>
              </:actions>
            </.simple_form>
          </div>
        </section>

        <section :if={@live_action == :show and @slot} class="rounded-3xl border border-slate-200 bg-white p-6 shadow-sm">
          <div class="flex flex-wrap items-start justify-between gap-4">
            <div class="min-w-0 flex-1">
              <div class="flex flex-wrap items-center gap-2">
                <h2 class="text-2xl font-semibold tracking-tight text-slate-950"><%= slot_target_title(@slot) %></h2>
                <span class={status_badge_class(@slot.status)}><%= slot_status_label(@slot.status) %></span>
              </div>
              <p class="mt-3 text-sm leading-7 text-slate-600"><%= slot_time_range(@slot) %></p>

              <dl class="mt-6 grid gap-4 md:grid-cols-2">
                <div class="rounded-2xl bg-slate-50 px-4 py-4">
                  <dt class="text-xs font-semibold uppercase tracking-[0.18em] text-slate-400">Booking Capacity</dt>
                  <dd class="mt-2 text-base font-semibold text-slate-900"><%= slot_capacity_label(@slot) %></dd>
                </div>
                <div class="rounded-2xl bg-slate-50 px-4 py-4">
                  <dt class="text-xs font-semibold uppercase tracking-[0.18em] text-slate-400">Booking Page</dt>
                  <dd class="mt-2 text-base font-semibold text-slate-900"><%= slot_booking_page_title(@slot) %></dd>
                </div>
              </dl>
            </div>

            <div class="flex flex-wrap items-center gap-2">
              <.link patch={~p"/company/console/slots/#{@slot.id}/edit"} class={action_link_class()}>Edit</.link>
              <.link patch={~p"/company/console/slots/#{@slot.id}/delete"} class={danger_action_link_class()}>Delete</.link>
            </div>
          </div>
        </section>

        <section :if={@live_action == :delete and @slot} class="rounded-3xl border border-danger-200 bg-danger-25 p-6 shadow-sm">
          <p class="text-xs font-semibold uppercase tracking-[0.18em] text-danger-700">Delete Slot</p>
          <h2 class="mt-2 text-2xl font-semibold tracking-tight text-slate-950"><%= slot_target_title(@slot) %></h2>
          <p class="mt-3 text-sm leading-6 text-slate-600">
            This removes the availability block entirely from all customer booking pages.
          </p>

          <div class="mt-5 flex flex-wrap items-center gap-3">
            <button
              type="button"
              phx-click="confirm_delete"
              class="inline-flex items-center gap-2 rounded-full bg-danger-600 px-5 py-2 text-sm font-semibold text-white transition hover:bg-danger-500"
            >
              <.icon name="hero-trash" class="h-4 w-4" />
              <span>Delete Slot</span>
            </button>
            <.link patch={~p"/company/console/slots/#{@slot.id}"} class="rounded-full px-4 py-2 text-sm font-medium text-slate-500 transition hover:bg-white hover:text-slate-900">
              Cancel
            </.link>
          </div>
        </section>
      </div>

      <:sidebar>
        <div class="space-y-4">
          <div class="rounded-3xl border border-slate-200 bg-white p-4 shadow-sm">
            <h2 class="text-lg font-semibold tracking-tight text-slate-950">Slot Snapshot</h2>
            <dl class="mt-3 space-y-3">
              <div class="flex items-center justify-between">
                <dt class="text-sm text-slate-500">Total</dt>
                <dd class="text-sm font-semibold text-slate-900"><%= @stats.total %></dd>
              </div>
              <div class="flex items-center justify-between">
                <dt class="text-sm text-slate-500">Available</dt>
                <dd class="text-sm font-semibold text-slate-900"><%= @stats.available %></dd>
              </div>
              <div class="flex items-center justify-between">
                <dt class="text-sm text-slate-500">Booked</dt>
                <dd class="text-sm font-semibold text-slate-900"><%= @stats.booked %></dd>
              </div>
              <div class="flex items-center justify-between">
                <dt class="text-sm text-slate-500">Cancelled</dt>
                <dd class="text-sm font-semibold text-slate-900"><%= @stats.cancelled %></dd>
              </div>
            </dl>
          </div>
        </div>
      </:sidebar>
    </.shell>
    """
  end

  def mount(_params, _session, socket) do
    company = CompanyConsole.ensure_company!(socket.assigns.current_user)

    {:ok,
     socket
     |> assign(:hide_global_user_menu, true)
     |> assign(:company, company)
     |> assign(:slot, nil)
     |> assign(:slots, [])
     |> assign(:form, nil)
     |> assign(:service_options, [])
     |> assign(:resource_options, [])
     |> assign(:booking_page_options, [])
     |> assign(:status_options, @status_options)
     |> assign(:has_targets, false)
     |> assign(:stats, %{total: 0, available: 0, booked: 0, cancelled: 0})
     |> assign(:page_title, "Company Slots")}
  end

  def handle_params(params, _uri, socket) do
    services = CompanyConsole.list_company_services(socket.assigns.current_user)
    resources = CompanyConsole.list_company_resources(socket.assigns.current_user)
    booking_pages = CompanyConsole.list_booking_pages(socket.assigns.current_user)
    slots = CompanyConsole.list_company_slots(socket.assigns.current_user)

    socket =
      socket
      |> assign(:service_options, build_service_options(services))
      |> assign(:resource_options, build_resource_options(resources))
      |> assign(:booking_page_options, build_booking_page_options(booking_pages))
      |> assign(:has_targets, services != [] or resources != [])
      |> assign(:slots, slots)
      |> assign(:stats, slot_stats(slots))

    case socket.assigns.live_action do
      :index ->
        {:noreply,
         socket
         |> assign(:page_title, "Company Slots")
         |> assign(:slot, nil)
         |> assign(:form, nil)}

      :new ->
        {:noreply,
         socket
         |> assign(:page_title, "Create Company Slot")
         |> assign(:slot, nil)
         |> assign(:form, to_form(default_slot_changeset(socket.assigns.current_user), as: :slot))}

      action ->
        load_slot(socket, params["id"], action)
    end
  end

  def handle_event("validate", %{"slot" => params}, socket) do
    changeset =
      socket
      |> slot_changeset_for_action(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset, as: :slot))}
  end

  def handle_event("save", %{"slot" => params}, socket) do
    case socket.assigns.live_action do
      :new ->
        case CompanyConsole.create_company_slot(socket.assigns.current_user, params) do
          {:ok, slot} ->
            {:noreply,
             socket
             |> put_flash(:info, "Company slot created.")
             |> push_patch(to: ~p"/company/console/slots/#{slot.id}")}

          {:error, changeset} ->
            {:noreply, assign(socket, :form, to_form(Map.put(changeset, :action, :insert), as: :slot))}
        end

      :edit ->
        case CompanyConsole.update_company_slot(socket.assigns.current_user, socket.assigns.slot, params) do
          {:ok, slot} ->
            {:noreply,
             socket
             |> put_flash(:info, "Company slot updated.")
             |> push_patch(to: ~p"/company/console/slots/#{slot.id}")}

          {:error, changeset} ->
            {:noreply, assign(socket, :form, to_form(Map.put(changeset, :action, :update), as: :slot))}
        end
    end
  end

  def handle_event("confirm_delete", _params, socket) do
    case CompanyConsole.delete_company_slot(socket.assigns.slot) do
      {:ok, _slot} ->
        {:noreply,
         socket
         |> put_flash(:info, "Company slot deleted.")
         |> push_patch(to: ~p"/company/console/slots")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Company slot could not be deleted.")}
    end
  end

  defp load_slot(socket, nil, _action) do
    {:noreply,
     socket
     |> put_flash(:error, "That company slot was not found.")
     |> push_patch(to: ~p"/company/console/slots")}
  end

  defp load_slot(socket, id, action) do
    case CompanyConsole.get_company_slot(socket.assigns.current_user, id) do
      nil ->
        {:noreply,
         socket
         |> put_flash(:error, "That company slot was not found.")
         |> push_patch(to: ~p"/company/console/slots")}

      slot ->
        {:noreply,
         socket
         |> assign(:slot, slot)
         |> assign(:page_title, company_slot_page_title(action, slot))
         |> assign(:form, form_for_action(socket.assigns.current_user, action, slot))}
    end
  end

  defp slot_changeset_for_action(%{assigns: %{live_action: :new, current_user: user}}, params) do
    CompanyConsole.change_company_slot(user, %CompanySlot{}, params)
  end

  defp slot_changeset_for_action(%{assigns: %{current_user: user, slot: slot}}, params) do
    CompanyConsole.change_company_slot(user, slot, params)
  end

  defp default_slot_changeset(user) do
    start_time = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.add(24 * 60 * 60, :second)
    end_time = DateTime.add(start_time, @default_slot_minutes * 60, :second)

    CompanyConsole.change_company_slot(user, %CompanySlot{}, %{
      "start_time" => start_time,
      "end_time" => end_time,
      "status" => "available",
      "source_type" => "manual",
      "booking_page_id" => nil,
      "max_bookings" => nil,
      "service_id" => nil,
      "resource_id" => nil
    })
  end

  defp form_for_action(_user, :show, _slot), do: nil
  defp form_for_action(_user, :delete, _slot), do: nil

  defp form_for_action(user, :edit, slot) do
    user
    |> CompanyConsole.change_company_slot(slot)
    |> to_form(as: :slot)
  end

  defp build_service_options(services), do: Enum.map(services, &{&1.name, &1.id})
  defp build_resource_options(resources), do: Enum.map(resources, &{&1.name, &1.id})
  defp build_booking_page_options(pages), do: Enum.map(pages, &{"#{&1.title} (#{CompanyConsole.public_url(&1)})", &1.id})

  defp slot_stats(slots) do
    %{
      total: length(slots),
      available: Enum.count(slots, &(&1.status == :available)),
      booked: Enum.count(slots, &(&1.status == :booked)),
      cancelled: Enum.count(slots, &(&1.status == :cancelled))
    }
  end

  defp company_slot_page_title(:show, slot), do: slot_target_title(slot)
  defp company_slot_page_title(:edit, slot), do: "Edit #{slot_target_title(slot)}"
  defp company_slot_page_title(:delete, slot), do: "Delete #{slot_target_title(slot)}"

  defp slot_page_label(:index), do: "Read"
  defp slot_page_label(:new), do: "Create"
  defp slot_page_label(:show), do: "Read"
  defp slot_page_label(:edit), do: "Update"
  defp slot_page_label(:delete), do: "Delete"

  defp cancel_slot_path(nil), do: ~p"/company/console/slots"
  defp cancel_slot_path(slot), do: ~p"/company/console/slots/#{slot.id}"

  defp slot_target_title(slot) do
    service_name = slot.service && slot.service.name
    resource_name = slot.resource && slot.resource.name

    case {service_name, resource_name} do
      {nil, nil} -> "Untargeted Slot"
      {service, nil} -> service
      {nil, resource} -> resource
      {service, resource} -> "#{service} + #{resource}"
    end
  end

  defp slot_time_range(slot) do
    "#{format_slot_datetime(slot.start_time)} to #{format_slot_datetime(slot.end_time)}"
  end

  defp slot_capacity_label(%{max_bookings: nil}), do: "Unlimited"
  defp slot_capacity_label(%{max_bookings: max_bookings}), do: "#{max_bookings} bookings"

  defp slot_booking_page_title(%{booking_page: %{title: title}}) when is_binary(title), do: title
  defp slot_booking_page_title(_slot), do: "Not pinned to a single booking page"

  defp format_slot_datetime(nil), do: "Unknown"
  defp format_slot_datetime(%DateTime{} = datetime), do: Calendar.strftime(datetime, "%Y-%m-%d %H:%M UTC")

  defp slot_visible_publicly?(%{status: :available, start_time: %DateTime{} = start_time}) do
    now = DateTime.utc_now()
    seven_days_later = DateTime.add(now, 7 * 24 * 60 * 60, :second)

    DateTime.compare(start_time, now) != :lt and DateTime.compare(start_time, seven_days_later) != :gt
  end

  defp slot_visible_publicly?(_slot), do: false

  defp slot_status_label(:available), do: "Available"
  defp slot_status_label(:booked), do: "Booked"
  defp slot_status_label(:cancelled), do: "Cancelled"
  defp slot_status_label(value), do: value |> to_string() |> String.capitalize()

  defp status_badge_class(:available), do: "rounded-full bg-emerald-50 px-2.5 py-1 text-[11px] font-semibold text-emerald-700"
  defp status_badge_class(:booked), do: "rounded-full bg-brand-50 px-2.5 py-1 text-[11px] font-semibold text-brand-700"
  defp status_badge_class(:cancelled), do: "rounded-full bg-slate-100 px-2.5 py-1 text-[11px] font-semibold text-slate-500"
  defp status_badge_class(_), do: "rounded-full bg-slate-100 px-2.5 py-1 text-[11px] font-semibold text-slate-500"

  defp action_link_class do
    "inline-flex items-center rounded-full px-3 py-2 text-sm font-medium text-slate-500 transition hover:bg-slate-100 hover:text-slate-900"
  end

  defp danger_action_link_class do
    "inline-flex items-center rounded-full px-3 py-2 text-sm font-medium text-danger-700 transition hover:bg-danger-50"
  end
end
