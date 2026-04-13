defmodule AinComBookingWeb.UserSlotLive do
  @moduledoc false
  use AinComBookingWeb, :live_view

  alias AinComBooking.Bookings.UserSlot
  alias AinComBooking.Catalog

  @status_options [
    {"Available", "available"},
    {"Booked", "booked"},
    {"Cancelled", "cancelled"}
  ]

  @default_slot_minutes 30

  def render(assigns) do
    ~H"""
    <style id="user-slot-live-style">
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
      <div class="mx-auto grid max-w-7xl gap-0 lg:grid-cols-[220px_minmax(0,1fr)_320px]">
        <aside class="border-b border-slate-200 bg-slate-50 lg:min-h-screen lg:border-b-0 lg:border-r">
          <div class="space-y-4 px-4 py-4">
            <div class="rounded-3xl border border-slate-200 bg-white px-4 py-5 shadow-sm">
              <div class="text-xs font-semibold uppercase tracking-[0.22em] text-brand-600">Slots</div>
              <div class="mt-3 text-2xl font-semibold tracking-tight text-slate-950">Manage Availability</div>
              <p class="mt-2 text-sm leading-6 text-slate-500">
                Create the actual time windows that power booking shares. Only future available slots show up in weekly booking modals.
              </p>
            </div>

            <nav class="space-y-2 rounded-3xl border border-slate-200 bg-white p-3 shadow-sm">
              <.link navigate={~p"/feed"} class={console_nav_class(false)}>
                <.icon name="hero-home-solid" class="h-5 w-5" />
                <span class="text-sm font-semibold">Home</span>
              </.link>
              <.link navigate={~p"/services"} class={console_nav_class(false)}>
                <.icon name="hero-briefcase" class="h-5 w-5" />
                <span class="text-sm font-semibold">Services</span>
              </.link>
              <.link patch={~p"/slots"} class={console_nav_class(true)}>
                <.icon name="hero-calendar-days" class="h-5 w-5" />
                <span class="text-sm font-semibold">Slots</span>
              </.link>
              <.link navigate={~p"/resources"} class={console_nav_class(false)}>
                <.icon name="hero-cube" class="h-5 w-5" />
                <span class="text-sm font-semibold">Resources</span>
              </.link>
              <.link navigate={~p"/users/search"} class={console_nav_class(false)}>
                <.icon name="hero-magnifying-glass" class="h-5 w-5" />
                <span class="text-sm font-semibold">Search</span>
              </.link>
              <.link navigate={~p"/users/settings"} class={console_nav_class(false)}>
                <.icon name="hero-cog-6-tooth" class="h-5 w-5" />
                <span class="text-sm font-semibold">Settings</span>
              </.link>
            </nav>

            <section class="rounded-3xl border border-slate-200 bg-white p-3 shadow-sm">
              <div class="flex items-center gap-3 rounded-2xl px-2 py-2">
                <div class="flex h-11 w-11 shrink-0 items-center justify-center rounded-full bg-slate-950 text-sm font-semibold text-white">
                  <%= initials(@current_user.name) %>
                </div>

                <div class="min-w-0 flex-1">
                  <div class="truncate text-sm font-semibold text-slate-950"><%= @current_user.name || "User" %></div>
                  <div class="truncate text-xs text-slate-400"><%= @current_user.email %></div>
                </div>
              </div>

              <div class="mt-2 space-y-1">
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

        <main class="min-w-0 border-b border-slate-200 bg-white lg:min-h-screen lg:border-x lg:border-b-0">
          <div class="sticky top-0 z-10 border-b border-slate-200 bg-white/90 px-4 py-3 backdrop-blur">
            <div class="flex flex-wrap items-center justify-between gap-3">
              <div>
                <h1 class="text-xl font-semibold tracking-tight text-slate-950"><%= @page_title %></h1>
                <p class="mt-0.5 text-xs font-medium uppercase tracking-[0.18em] text-slate-400"><%= slot_page_label(@live_action) %></p>
              </div>

              <.link
                :if={@live_action != :new}
                patch={~p"/slots/new"}
                class="inline-flex items-center gap-2 rounded-full bg-brand-600 px-4 py-2 text-sm font-semibold text-white transition hover:bg-brand-500"
              >
                <.icon name="hero-plus" class="h-4 w-4" />
                <span>New Slot</span>
              </.link>
            </div>
          </div>

          <section :if={@live_action == :index} class="space-y-4 px-4 py-4">
            <div :if={@slots == []} class="rounded-3xl border border-dashed border-slate-300 bg-slate-50 px-6 py-10 text-center text-sm text-slate-500">
              No slots yet. Create a slot so your shares have actual booking windows.
            </div>

            <article
              :for={slot <- @slots}
              id={"slot-#{slot.id}"}
              class="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm"
            >
              <div class="flex flex-wrap items-start justify-between gap-4">
                <div class="min-w-0 flex-1">
                  <div class="flex flex-wrap items-center gap-2">
                    <h2 class="text-lg font-semibold tracking-tight text-slate-950"><%= slot_target_title(slot) %></h2>
                    <span class={status_badge_class(slot.status)}>
                      <%= slot_status_label(slot.status) %>
                    </span>
                    <span :if={slot_visible_in_feed?(slot)} class="rounded-full bg-brand-50 px-2.5 py-1 text-[11px] font-semibold text-brand-700">
                      Visible in weekly shares
                    </span>
                  </div>

                  <p class="mt-2 text-sm leading-6 text-slate-600"><%= slot_time_range(slot) %></p>
                  <div class="mt-3 flex flex-wrap items-center gap-4 text-xs font-medium text-slate-400">
                    <span class="inline-flex items-center gap-1">
                      <.icon name="hero-clock" class="h-4 w-4" />
                      <%= slot_duration_minutes(slot) %> min
                    </span>
                    <span :if={slot.service} class="inline-flex items-center gap-1">
                      <.icon name="hero-briefcase" class="h-4 w-4" />
                      <%= slot.service.name %>
                    </span>
                    <span :if={slot.resource} class="inline-flex items-center gap-1">
                      <.icon name="hero-cube" class="h-4 w-4" />
                      <%= slot.resource.name %>
                    </span>
                  </div>
                </div>

                <div class="flex flex-wrap items-center gap-2">
                  <.link patch={~p"/slots/#{slot.id}"} class={action_link_class()}>
                    View
                  </.link>
                  <.link patch={~p"/slots/#{slot.id}/edit"} class={action_link_class()}>
                    Edit
                  </.link>
                  <.link patch={~p"/slots/#{slot.id}/delete"} class={danger_action_link_class()}>
                    Delete
                  </.link>
                </div>
              </div>
            </article>
          </section>

          <section :if={@live_action == :new or @live_action == :edit} class="space-y-4 px-4 py-4">
            <div :if={!@has_targets} class="rounded-3xl border border-dashed border-warning-300 bg-warning-50 px-5 py-4 text-sm leading-6 text-warning-900">
              Create at least one service or resource first. Slots must attach to a bookable target.
            </div>

            <div class="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
              <.simple_form for={@form} as={:slot} id="slot-form" phx-change="validate" phx-submit="save">
                <div class="grid gap-4 md:grid-cols-2">
                  <.input field={@form[:start_time]} type="datetime-local" label="Start time (UTC)" />
                  <.input field={@form[:end_time]} type="datetime-local" label="End time (UTC)" />
                  <.input field={@form[:status]} type="select" label="Status" options={@status_options} />
                  <.input field={@form[:service_id]} type="select" label="Service" prompt="Optional" options={@service_options} />
                  <.input field={@form[:resource_id]} type="select" label="Resource" prompt="Optional" options={@resource_options} />
                </div>

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

          <section :if={@live_action == :show and @slot} class="space-y-4 px-4 py-4">
            <article class="rounded-3xl border border-slate-200 bg-white p-6 shadow-sm">
              <div class="flex flex-wrap items-start justify-between gap-4">
                <div class="min-w-0 flex-1">
                  <div class="flex flex-wrap items-center gap-2">
                    <h2 class="text-2xl font-semibold tracking-tight text-slate-950"><%= slot_target_title(@slot) %></h2>
                    <span class={status_badge_class(@slot.status)}>
                      <%= slot_status_label(@slot.status) %>
                    </span>
                  </div>
                  <p class="mt-3 text-sm leading-7 text-slate-600"><%= slot_time_range(@slot) %></p>
                </div>

                <div class="flex flex-wrap items-center gap-2">
                  <.link patch={~p"/slots/#{@slot.id}/edit"} class={action_link_class()}>
                    Edit
                  </.link>
                  <.link patch={~p"/slots/#{@slot.id}/delete"} class={danger_action_link_class()}>
                    Delete
                  </.link>
                </div>
              </div>

              <dl class="mt-6 grid gap-4 md:grid-cols-2">
                <div class="rounded-2xl bg-slate-50 px-4 py-4">
                  <dt class="text-xs font-semibold uppercase tracking-[0.18em] text-slate-400">Duration</dt>
                  <dd class="mt-2 text-base font-semibold text-slate-900"><%= slot_duration_minutes(@slot) %> minutes</dd>
                </div>
                <div class="rounded-2xl bg-slate-50 px-4 py-4">
                  <dt class="text-xs font-semibold uppercase tracking-[0.18em] text-slate-400">Weekly Share Visibility</dt>
                  <dd class="mt-2 text-base font-semibold text-slate-900"><%= if slot_visible_in_feed?(@slot), do: "Visible now", else: "Hidden until it is future + available" %></dd>
                </div>
                <div class="rounded-2xl bg-slate-50 px-4 py-4">
                  <dt class="text-xs font-semibold uppercase tracking-[0.18em] text-slate-400">Service</dt>
                  <dd class="mt-2 text-base font-semibold text-slate-900"><%= @slot.service && @slot.service.name || "None" %></dd>
                </div>
                <div class="rounded-2xl bg-slate-50 px-4 py-4">
                  <dt class="text-xs font-semibold uppercase tracking-[0.18em] text-slate-400">Resource</dt>
                  <dd class="mt-2 text-base font-semibold text-slate-900"><%= @slot.resource && @slot.resource.name || "None" %></dd>
                </div>
              </dl>
            </article>
          </section>

          <section :if={@live_action == :delete and @slot} class="px-4 py-4">
            <div class="rounded-3xl border border-danger-200 bg-danger-25 p-6 shadow-sm">
              <p class="text-xs font-semibold uppercase tracking-[0.18em] text-danger-700">Delete Slot</p>
              <h2 class="mt-2 text-2xl font-semibold tracking-tight text-slate-950"><%= slot_target_title(@slot) %></h2>
              <p class="mt-3 text-sm leading-6 text-slate-600">
                This removes the time block completely. Any social post pointing at this slot's service or resource may lose a bookable window.
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
                <.link patch={~p"/slots/#{@slot.id}"} class="rounded-full px-4 py-2 text-sm font-medium text-slate-500 transition hover:bg-white hover:text-slate-900">
                  Cancel
                </.link>
              </div>
            </div>
          </section>
        </main>

        <aside class="bg-slate-50 lg:min-h-screen lg:border-l lg:border-slate-200">
          <div class="space-y-4 px-4 py-4">
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

            <div class="rounded-3xl border border-slate-200 bg-white p-4 shadow-sm">
              <h2 class="text-lg font-semibold tracking-tight text-slate-950">How It Affects Feed</h2>
              <div class="mt-3 space-y-2 text-sm leading-6 text-slate-600">
                <p>`View Weekly Slots` only shows slots with status `available`.</p>
                <p>The slot start time must still be in the future and within the next 7 days.</p>
                <p>Past, booked, or cancelled slots stay in your console but disappear from booking modals.</p>
              </div>
            </div>
          </div>
        </aside>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:hide_global_user_menu, true)
     |> assign(:slot, nil)
     |> assign(:form, nil)
     |> assign(:slots, [])
     |> assign(:service_options, [])
     |> assign(:resource_options, [])
     |> assign(:status_options, @status_options)
     |> assign(:stats, %{total: 0, available: 0, booked: 0, cancelled: 0})
     |> assign(:has_targets, false)
     |> assign(:page_title, "Slots")}
  end

  def handle_params(params, _uri, socket) do
    services = Catalog.list_user_services(socket.assigns.current_user)
    resources = Catalog.list_user_resources(socket.assigns.current_user)
    slots = Catalog.list_user_slots(socket.assigns.current_user)

    socket =
      socket
      |> assign(:slots, slots)
      |> assign(:service_options, build_service_options(services))
      |> assign(:resource_options, build_resource_options(resources))
      |> assign(:has_targets, services != [] or resources != [])
      |> assign(:stats, slot_stats(slots))

    case socket.assigns.live_action do
      :index ->
        {:noreply,
         socket
         |> assign(:page_title, "My Slots")
         |> assign(:slot, nil)
         |> assign(:form, nil)}

      :new ->
        {:noreply,
         socket
         |> assign(:page_title, "Create Slot")
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
        case Catalog.create_user_slot(socket.assigns.current_user, params) do
          {:ok, slot} ->
            {:noreply,
             socket
             |> put_flash(:info, "Slot created.")
             |> push_patch(to: ~p"/slots/#{slot.id}")}

          {:error, changeset} ->
            {:noreply, assign(socket, :form, to_form(Map.put(changeset, :action, :insert), as: :slot))}
        end

      :edit ->
        case Catalog.update_user_slot(socket.assigns.current_user, socket.assigns.slot, params) do
          {:ok, slot} ->
            {:noreply,
             socket
             |> put_flash(:info, "Slot updated.")
             |> push_patch(to: ~p"/slots/#{slot.id}")}

          {:error, changeset} ->
            {:noreply, assign(socket, :form, to_form(Map.put(changeset, :action, :update), as: :slot))}
        end
    end
  end

  def handle_event("confirm_delete", _params, socket) do
    case Catalog.delete_user_slot(socket.assigns.slot) do
      {:ok, _slot} ->
        {:noreply,
         socket
         |> put_flash(:info, "Slot deleted.")
         |> push_patch(to: ~p"/slots")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Slot could not be deleted.")}
    end
  end

  defp load_slot(socket, nil, _action) do
    {:noreply,
     socket
     |> put_flash(:error, "That slot was not found.")
     |> push_patch(to: ~p"/slots")}
  end

  defp load_slot(socket, id, action) do
    case Catalog.get_user_slot(socket.assigns.current_user, id) do
      nil ->
        {:noreply,
         socket
         |> put_flash(:error, "That slot was not found.")
         |> push_patch(to: ~p"/slots")}

      slot ->
        socket =
          socket
          |> assign(:slot, slot)
          |> assign(:page_title, page_title(action, slot))
          |> assign(:form, form_for_action(socket.assigns.current_user, action, slot))

        {:noreply, socket}
    end
  end

  defp slot_changeset_for_action(%{assigns: %{live_action: :new, current_user: user}}, params) do
    Catalog.change_user_slot(user, %UserSlot{}, params)
  end

  defp slot_changeset_for_action(%{assigns: %{current_user: user, slot: slot}}, params) do
    Catalog.change_user_slot(user, slot, params)
  end

  defp default_slot_changeset(user) do
    start_time = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.add(24 * 60 * 60, :second)
    end_time = DateTime.add(start_time, @default_slot_minutes * 60, :second)

    Catalog.change_user_slot(user, %UserSlot{}, %{
      "start_time" => start_time,
      "end_time" => end_time,
      "status" => "available",
      "service_id" => nil,
      "resource_id" => nil
    })
  end

  defp form_for_action(_user, :show, _slot), do: nil
  defp form_for_action(_user, :delete, _slot), do: nil

  defp form_for_action(user, :edit, slot) do
    user
    |> Catalog.change_user_slot(slot)
    |> to_form(as: :slot)
  end

  defp build_service_options(services) do
    Enum.map(services, fn service ->
      {service.name, service.id}
    end)
  end

  defp build_resource_options(resources) do
    Enum.map(resources, fn resource ->
      {resource.name, resource.id}
    end)
  end

  defp slot_stats(slots) do
    %{
      total: length(slots),
      available: Enum.count(slots, &(&1.status == :available)),
      booked: Enum.count(slots, &(&1.status == :booked)),
      cancelled: Enum.count(slots, &(&1.status == :cancelled))
    }
  end

  defp slot_page_label(:index), do: "Read"
  defp slot_page_label(:new), do: "Create"
  defp slot_page_label(:show), do: "Read"
  defp slot_page_label(:edit), do: "Update"
  defp slot_page_label(:delete), do: "Delete"

  defp page_title(:show, slot), do: slot_target_title(slot)
  defp page_title(:edit, slot), do: "Edit #{slot_target_title(slot)}"
  defp page_title(:delete, slot), do: "Delete #{slot_target_title(slot)}"

  defp cancel_slot_path(nil), do: ~p"/slots"
  defp cancel_slot_path(slot), do: ~p"/slots/#{slot.id}"

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

  defp format_slot_datetime(nil), do: "Unknown"

  defp format_slot_datetime(%DateTime{} = datetime) do
    Calendar.strftime(datetime, "%Y-%m-%d %H:%M UTC")
  end

  defp slot_duration_minutes(%{start_time: %DateTime{} = start_time, end_time: %DateTime{} = end_time}) do
    end_time
    |> DateTime.diff(start_time, :second)
    |> div(60)
  end

  defp slot_duration_minutes(_slot), do: 0

  defp slot_visible_in_feed?(%{status: :available, start_time: %DateTime{} = start_time}) do
    now = DateTime.utc_now()
    seven_days_later = DateTime.add(now, 7 * 24 * 60 * 60, :second)

    DateTime.compare(start_time, now) != :lt and DateTime.compare(start_time, seven_days_later) != :gt
  end

  defp slot_visible_in_feed?(_slot), do: false

  defp slot_status_label(:available), do: "Available"
  defp slot_status_label(:booked), do: "Booked"
  defp slot_status_label(:cancelled), do: "Cancelled"
  defp slot_status_label(value), do: value |> to_string() |> String.capitalize()

  defp status_badge_class(:available) do
    "rounded-full bg-emerald-50 px-2.5 py-1 text-[11px] font-semibold text-emerald-700"
  end

  defp status_badge_class(:booked) do
    "rounded-full bg-brand-50 px-2.5 py-1 text-[11px] font-semibold text-brand-700"
  end

  defp status_badge_class(:cancelled) do
    "rounded-full bg-slate-100 px-2.5 py-1 text-[11px] font-semibold text-slate-500"
  end

  defp status_badge_class(_status) do
    "rounded-full bg-slate-100 px-2.5 py-1 text-[11px] font-semibold text-slate-500"
  end

  defp console_nav_class(true), do: "flex items-center gap-3 rounded-2xl bg-slate-950 px-4 py-3 text-white transition"

  defp console_nav_class(false) do
    "flex items-center gap-3 rounded-2xl px-4 py-3 text-slate-500 transition hover:bg-slate-100 hover:text-slate-900"
  end

  defp action_link_class do
    "inline-flex items-center rounded-full px-3 py-2 text-sm font-medium text-slate-500 transition hover:bg-slate-100 hover:text-slate-900"
  end

  defp danger_action_link_class do
    "inline-flex items-center rounded-full px-3 py-2 text-sm font-medium text-danger-700 transition hover:bg-danger-50"
  end

  defp initials(name) do
    name
    |> to_string()
    |> String.split(~r/\s+/, trim: true)
    |> Enum.take(2)
    |> Enum.map_join("", &String.first/1)
    |> case do
      "" -> "U"
      initials -> String.upcase(initials)
    end
  end
end
