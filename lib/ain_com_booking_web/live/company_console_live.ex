defmodule AinComBookingWeb.CompanyConsoleLive do
  @moduledoc false
  use AinComBookingWeb, :live_view

  import AinComBookingWeb.CompanyConsoleComponents

  alias AinComBooking.CompanyConsole

  def render(assigns) do
    ~H"""
    <.shell
      current_user={@current_user}
      company={@company}
      active_section={:dashboard}
      page_title="Company Dashboard"
      page_label="Overview"
      page_subtitle="Company customers land here after sign in. From here you can manage bookable inventory and published booking URLs."
    >
      <div class="space-y-6">
        <section class="overflow-hidden rounded-3xl border border-slate-200 bg-gradient-to-br from-slate-950 via-slate-900 to-slate-800 p-6 text-white shadow-sm">
          <div class="grid gap-5 lg:grid-cols-[minmax(0,1fr)_280px]">
            <div>
              <div class="text-xs font-semibold uppercase tracking-[0.22em] text-slate-300">Performance Snapshot</div>
              <h2 class="mt-3 text-3xl font-semibold tracking-tight">Keep bookings moving without leaving this console.</h2>
              <p class="mt-3 max-w-2xl text-sm leading-7 text-slate-300">
                Your company inventory, booking pages, and customer reservations are tracked here. Use this view to spot publishing gaps and respond to new bookings quickly.
              </p>

              <div class="mt-5 space-y-3">
                <div class="flex items-center justify-between gap-4 rounded-2xl border border-white/10 bg-white/5 px-4 py-4">
                  <div class="text-[11px] font-semibold uppercase tracking-[0.18em] text-slate-300">Total Bookings</div>
                  <div class="text-2xl font-semibold"><%= @snapshot.bookings %></div>
                </div>
                <div class="flex items-center justify-between gap-4 rounded-2xl border border-white/10 bg-white/5 px-4 py-4">
                  <div class="text-[11px] font-semibold uppercase tracking-[0.18em] text-slate-300">Last 7 Days</div>
                  <div class="text-2xl font-semibold"><%= @snapshot.bookings_last_7_days %></div>
                </div>
                <div class="flex items-center justify-between gap-4 rounded-2xl border border-white/10 bg-white/5 px-4 py-4">
                  <div class="text-[11px] font-semibold uppercase tracking-[0.18em] text-slate-300">Last 7 Days Revenue</div>
                  <div class="text-2xl font-semibold">
                    <%= money_total(@snapshot.revenue_last_7_days, @snapshot.revenue_last_7_days_currency) %>
                  </div>
                </div>
                <div class="flex items-center justify-between gap-4 rounded-2xl border border-white/10 bg-white/5 px-4 py-4">
                  <div class="text-[11px] font-semibold uppercase tracking-[0.18em] text-slate-300">Published Pages</div>
                  <div class="text-2xl font-semibold"><%= @snapshot.published_pages %></div>
                </div>
              </div>
            </div>

            <div class="rounded-3xl border border-white/10 bg-white/5 p-5">
              <div class="flex items-center justify-between gap-3">
                <div class="text-xs font-semibold uppercase tracking-[0.18em] text-slate-300">Next Available Slot</div>
                <span class={slot_status_class(@snapshot.next_open_slot)}><%= slot_status_text(@snapshot.next_open_slot) %></span>
              </div>
              <div class="mt-4 text-base font-semibold leading-7">
                <%= next_open_slot_label(@snapshot.next_open_slot) %>
              </div>
              <p class="mt-2 text-sm leading-6 text-slate-300">
                <%= next_open_slot_time(@snapshot.next_open_slot) %>
              </p>
              <div class="mt-5 flex flex-wrap gap-2">
                <.link
                  navigate={~p"/company/console/services"}
                  class="rounded-full bg-white px-4 py-2 text-sm font-semibold text-slate-950 transition hover:bg-slate-100"
                >
                  Review Services
                </.link>
                <.link
                  navigate={~p"/company/console/resources"}
                  class="rounded-full border border-white/20 px-4 py-2 text-sm font-semibold text-white transition hover:bg-white/10"
                >
                  Review Resources
                </.link>
              </div>
            </div>
          </div>
        </section>

        <section class="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
          <div class="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
            <div class="text-xs font-semibold uppercase tracking-[0.18em] text-slate-400">Services</div>
            <div class="mt-3 text-3xl font-semibold tracking-tight text-slate-950"><%= @snapshot.services %></div>
            <p class="mt-2 text-sm text-slate-500">Bookable offers configured for company customers.</p>
          </div>
          <div class="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
            <div class="text-xs font-semibold uppercase tracking-[0.18em] text-slate-400">Resources</div>
            <div class="mt-3 text-3xl font-semibold tracking-tight text-slate-950"><%= @snapshot.resources %></div>
            <p class="mt-2 text-sm text-slate-500">Rooms, equipment, and other inventory attached to bookings.</p>
          </div>
          <div class="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
            <div class="text-xs font-semibold uppercase tracking-[0.18em] text-slate-400">Draft Pages</div>
            <div class="mt-3 text-3xl font-semibold tracking-tight text-slate-950"><%= @snapshot.draft_pages %></div>
            <p class="mt-2 text-sm text-slate-500">Pages that still need to be published before customers can book.</p>
          </div>
          <div class="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
            <div class="text-xs font-semibold uppercase tracking-[0.18em] text-slate-400">Booked Slots</div>
            <div class="mt-3 text-3xl font-semibold tracking-tight text-slate-950"><%= @snapshot.booked_slots %></div>
            <p class="mt-2 text-sm text-slate-500">Inventory already committed to confirmed reservations.</p>
          </div>
        </section>

        <section class="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
          <div class="flex flex-wrap items-center justify-between gap-3">
            <div>
              <h2 class="text-lg font-semibold tracking-tight text-slate-950">Recent Customer Bookings</h2>
              <p class="mt-1 text-sm text-slate-500">The latest confirmed activity from your published booking pages.</p>
            </div>
            <div class="flex items-center gap-3">
              <div class="rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold uppercase tracking-[0.16em] text-slate-500">
                <%= @snapshot.bookings %> total
              </div>
            </div>
          </div>

          <div :if={@recent_bookings == []} class="mt-4 rounded-2xl border border-dashed border-slate-300 bg-slate-50 px-4 py-8 text-sm text-slate-500">
            No customer bookings yet. Publish a booking page and share the URL to start collecting reservations.
          </div>

          <div :if={@recent_bookings != []} class="mt-4 space-y-3">
            <div
              :for={booking <- @recent_bookings}
              class="rounded-2xl border border-slate-200 bg-slate-50 px-4 py-4 transition hover:border-slate-300 hover:bg-white"
            >
              <div class="flex flex-wrap items-start justify-between gap-3">
                <div class="min-w-0 flex-1">
                  <div class="flex flex-wrap items-center gap-2">
                    <h3 class="text-sm font-semibold text-slate-950"><%= booking.customer_name %></h3>
                    <span class={booking_status_class(booking.status)}><%= booking.status %></span>
                  </div>
                  <p class="mt-2 text-sm font-medium text-slate-700"><%= booking_target_name(booking) %></p>
                  <p class="mt-1 text-xs text-slate-400"><%= booking_slot_window(booking) %></p>
                  <p class="mt-3 text-xs uppercase tracking-[0.16em] text-slate-400">
                    booked <%= inserted_at_label(booking.inserted_at) %>
                  </p>

                  <div class="mt-3 flex flex-wrap gap-2">
                    <.link :if={booking.service_id} navigate={~p"/company/console/services/#{booking.service_id}"} class={mini_action_link_class()}>
                      Service
                    </.link>
                    <.link :if={booking.resource_id} navigate={~p"/company/console/resources/#{booking.resource_id}"} class={mini_action_link_class()}>
                      Resource
                    </.link>
                  </div>
                </div>

                <div class="rounded-2xl border border-slate-200 bg-white px-3 py-3 text-right">
                  <div class="text-[11px] font-semibold uppercase tracking-[0.18em] text-slate-400">Amount</div>
                  <div class="mt-1 text-sm font-semibold text-slate-950"><%= booking_total_label(booking) %></div>
                </div>
              </div>
            </div>
          </div>
        </section>
      </div>

      <:sidebar>
        <div class="space-y-4">
          <div class="rounded-3xl border border-slate-200 bg-white p-4 shadow-sm">
            <h2 class="text-lg font-semibold tracking-tight text-slate-950">Publishing Funnel</h2>
            <dl class="mt-3 space-y-3">
              <div class="flex items-center justify-between">
                <dt class="text-sm text-slate-500">Booking pages</dt>
                <dd class="text-sm font-semibold text-slate-900"><%= @snapshot.pages %></dd>
              </div>
              <div class="flex items-center justify-between">
                <dt class="text-sm text-slate-500">Published</dt>
                <dd class="text-sm font-semibold text-emerald-700"><%= @snapshot.published_pages %></dd>
              </div>
              <div class="flex items-center justify-between">
                <dt class="text-sm text-slate-500">Drafts</dt>
                <dd class="text-sm font-semibold text-amber-700"><%= @snapshot.draft_pages %></dd>
              </div>
              <div class="flex items-center justify-between">
                <dt class="text-sm text-slate-500">Total slots</dt>
                <dd class="text-sm font-semibold text-slate-900"><%= @snapshot.slots %></dd>
              </div>
            </dl>
          </div>

          <div class="rounded-3xl border border-slate-200 bg-white p-4 shadow-sm">
            <div class="flex items-center justify-between gap-3">
              <h2 class="text-lg font-semibold tracking-tight text-slate-950">Recent Booking Pages</h2>
            </div>

            <div :if={@recent_pages == []} class="mt-4 rounded-2xl border border-dashed border-slate-300 bg-slate-50 px-4 py-6 text-sm text-slate-500">
              No booking pages yet. Create one from a service or resource detail page.
            </div>

            <div :if={@recent_pages != []} class="mt-4 space-y-3">
              <div :for={page <- @recent_pages} class="rounded-2xl border border-slate-200 bg-slate-50 px-4 py-4">
                <div class="flex flex-wrap items-center justify-between gap-2">
                  <div class="min-w-0 flex-1">
                    <div class="truncate text-sm font-semibold text-slate-950"><%= page.title %></div>
                    <div class="mt-1 truncate text-xs text-slate-400"><%= page_target_name(page) %></div>
                    <div class="mt-1 truncate text-xs text-slate-400"><%= CompanyConsole.public_url(page) %></div>
                  </div>
                  <span class={page_status_class(page.is_published)}>
                    <%= if page.is_published, do: "Published", else: "Draft" %>
                  </span>
                </div>
              </div>
            </div>
          </div>

          <div class="rounded-3xl border border-slate-200 bg-white p-4 shadow-sm">
            <h2 class="text-lg font-semibold tracking-tight text-slate-950">Quick Actions</h2>
            <div class="mt-4 space-y-2">
              <.link navigate={~p"/company/console/services/new"} class={action_link_class()}>
                Create service
              </.link>
              <.link navigate={~p"/company/console/resources/new"} class={action_link_class()}>
                Create resource
              </.link>
              <.link navigate={~p"/company/console/services"} class={action_link_class()}>
                Review services
              </.link>
            </div>
          </div>

          <div class="rounded-3xl border border-slate-200 bg-white p-4 shadow-sm">
            <h2 class="text-lg font-semibold tracking-tight text-slate-950">How To Launch</h2>
            <div class="mt-4 space-y-3 text-sm leading-6 text-slate-600">
              <p>1. Create a company service or resource.</p>
              <p>2. Open each detail page and generate manual/automatic slots.</p>
              <p>3. Check booked customers from the service/resource booked modal.</p>
              <p>4. Keep upcoming slots available so customers can reserve in time.</p>
            </div>
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
     |> assign(:snapshot, CompanyConsole.dashboard_snapshot(socket.assigns.current_user))
     |> assign(:recent_pages, CompanyConsole.recent_booking_pages(socket.assigns.current_user))
     |> assign(:recent_bookings, CompanyConsole.recent_company_bookings(socket.assigns.current_user))}
  end

  defp page_status_class(true), do: "rounded-full bg-emerald-50 px-2.5 py-1 text-[11px] font-semibold text-emerald-700"
  defp page_status_class(false), do: "rounded-full bg-slate-100 px-2.5 py-1 text-[11px] font-semibold text-slate-500"

  defp booking_status_class("confirmed"), do: "rounded-full bg-emerald-50 px-2 py-0.5 text-[11px] font-semibold uppercase tracking-[0.16em] text-emerald-700"
  defp booking_status_class("cancelled"), do: "rounded-full bg-rose-50 px-2 py-0.5 text-[11px] font-semibold uppercase tracking-[0.16em] text-rose-700"
  defp booking_status_class(_status), do: "rounded-full bg-slate-100 px-2 py-0.5 text-[11px] font-semibold uppercase tracking-[0.16em] text-slate-500"

  defp slot_status_class(nil), do: "rounded-full bg-slate-700 px-2 py-1 text-[11px] font-semibold uppercase tracking-[0.18em] text-slate-300"
  defp slot_status_class(_slot), do: "rounded-full bg-emerald-400/15 px-2 py-1 text-[11px] font-semibold uppercase tracking-[0.18em] text-emerald-200"

  defp slot_status_text(nil), do: "Empty"
  defp slot_status_text(_slot), do: "Live"

  defp action_link_class do
    "block rounded-2xl border border-slate-200 px-3 py-3 text-sm font-semibold text-slate-700 transition hover:border-slate-300 hover:bg-slate-50 hover:text-slate-950"
  end

  defp mini_action_link_class do
    "rounded-full border border-slate-200 px-2.5 py-1 text-[11px] font-semibold uppercase tracking-[0.16em] text-slate-500 transition hover:border-slate-300 hover:bg-slate-100 hover:text-slate-900"
  end

  defp page_target_name(%{service: %{name: service_name}, resource: %{name: resource_name}}) when is_binary(service_name) and is_binary(resource_name) do
    "#{service_name} + #{resource_name}"
  end

  defp page_target_name(%{service: %{name: service_name}}) when is_binary(service_name), do: "Service: #{service_name}"
  defp page_target_name(%{resource: %{name: resource_name}}) when is_binary(resource_name), do: "Resource: #{resource_name}"
  defp page_target_name(_page), do: "Booking Target"

  defp booking_target_name(%{service: %{name: service_name}, resource: %{name: resource_name}}) when is_binary(service_name) and is_binary(resource_name) do
    "#{service_name} + #{resource_name}"
  end

  defp booking_target_name(%{service: %{name: service_name}}) when is_binary(service_name), do: service_name
  defp booking_target_name(%{resource: %{name: resource_name}}) when is_binary(resource_name), do: resource_name
  defp booking_target_name(_booking), do: "Booking"

  defp booking_slot_window(%{slot: %{start_time: start_time, end_time: end_time}}) do
    "#{format_datetime(start_time)} to #{format_datetime(end_time)}"
  end

  defp booking_slot_window(_booking), do: "Slot details unavailable"

  defp booking_total_label(%{total_price: total_price, currency: currency}) do
    "#{total_price || 0} #{currency || "KRW"}"
  end

  defp money_total(total, nil), do: "#{total || 0} (mixed)"
  defp money_total(total, currency), do: "#{total || 0} #{currency}"

  defp inserted_at_label(%NaiveDateTime{} = inserted_at), do: Calendar.strftime(inserted_at, "%Y-%m-%d %H:%M")
  defp inserted_at_label(%DateTime{} = inserted_at), do: Calendar.strftime(inserted_at, "%Y-%m-%d %H:%M")
  defp inserted_at_label(_inserted_at), do: "recently"

  defp next_open_slot_label(nil), do: "No open slot scheduled yet"

  defp next_open_slot_label(slot) do
    case booking_target_name(slot) do
      "Booking" -> "Open slot"
      label -> label
    end
  end

  defp next_open_slot_time(nil), do: "Create a future available slot so customers can reserve time."

  defp next_open_slot_time(%{start_time: start_time, end_time: end_time}) do
    "#{format_datetime(start_time)} to #{format_datetime(end_time)}"
  end

  defp format_datetime(%DateTime{} = datetime), do: Calendar.strftime(datetime, "%Y-%m-%d %H:%M UTC")
  defp format_datetime(%NaiveDateTime{} = datetime), do: Calendar.strftime(datetime, "%Y-%m-%d %H:%M")
  defp format_datetime(_datetime), do: "Unknown"
end
