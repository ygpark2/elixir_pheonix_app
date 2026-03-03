defmodule AinComBookingWeb.CompanyPublicBookingPageLive do
  @moduledoc false
  use AinComBookingWeb, :live_view

  alias AinComBooking.CompanyConsole

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
              <div class="flex items-center justify-between gap-3">
                <h2 class="text-lg font-semibold tracking-tight text-slate-950">Open Times In The Next 7 Days</h2>
                <div class="flex items-center gap-3">
                  <span class="rounded-full bg-slate-100 px-3 py-1 text-[11px] font-semibold uppercase tracking-[0.16em] text-slate-500">
                    <%= CompanyConsole.company_timezone(@page) %>
                  </span>
                  <span class="text-sm font-semibold text-slate-500"><%= length(@slots) %> open</span>
                </div>
              </div>

              <div :if={@slots == []} class="mt-4 rounded-2xl border border-dashed border-slate-300 bg-slate-50 px-4 py-8 text-sm text-slate-500">
                No open slots are available right now. Please check back later.
              </div>

              <div :if={@slots != []} class="mt-4 space-y-2">
                <button
                  :for={slot <- @slots}
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
    slots = if page, do: CompanyConsole.list_upcoming_slots_for_page(page), else: []

    {:ok,
     socket
     |> assign(:page, page)
     |> assign(:slots, slots)
     |> assign(:selected_slot_id, default_slot_id(slots))
     |> assign(:booking_form, blank_booking_form())}
  end

  def handle_event("select_slot", %{"slot_id" => slot_id}, socket) do
    {:noreply, assign(socket, :selected_slot_id, slot_id)}
  end

  def handle_event("book", %{"booking" => _params}, %{assigns: %{page: nil}} = socket) do
    {:noreply, put_flash(socket, :error, "This booking page is not available.")}
  end

  def handle_event("book", %{"booking" => params}, socket) do
    attrs = Map.put(params, "slot_id", socket.assigns.selected_slot_id)

    case CompanyConsole.create_booking_from_page(socket.assigns.page, attrs) do
      {:ok, _booking} ->
        slots = CompanyConsole.list_upcoming_slots_for_page(socket.assigns.page)

        {:noreply,
         socket
         |> put_flash(:info, "Your booking is confirmed.")
         |> assign(:slots, slots)
         |> assign(:selected_slot_id, default_slot_id(slots))
         |> assign(:booking_form, blank_booking_form())}

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

  defp default_slot_id([slot | _rest]), do: slot.id
  defp default_slot_id([]), do: nil

  defp selected_slot_summary(_page, _slots, nil), do: "Select an available time on the left."

  defp selected_slot_summary(page, slots, selected_slot_id) do
    case Enum.find(slots, fn slot -> slot.id == selected_slot_id end) do
      nil -> "Select an available time on the left."
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

  defp page_shell_class(%{theme: "warm"}), do: "min-h-screen bg-gradient-to-b from-amber-50 via-white to-rose-50"
  defp page_shell_class(%{theme: "neutral"}), do: "min-h-screen bg-gradient-to-b from-slate-100 via-white to-slate-50"
  defp page_shell_class(_page), do: "min-h-screen bg-gradient-to-b from-brand-50 via-white to-slate-50"

  defp present?(value), do: value not in [nil, ""]
end
