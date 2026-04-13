defmodule AinComBookingWeb.SharedBookingPostLive do
  @moduledoc false
  use AinComBookingWeb, :live_view

  alias AinComBooking.Social

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-[#f7f9f9] font-outfit text-slate-900">
      <div class="mx-auto grid max-w-6xl gap-0 lg:grid-cols-[minmax(0,1fr)_320px]">
        <main class="min-w-0 border-x border-slate-200 bg-white">
          <div class="sticky top-0 z-10 border-b border-slate-200 bg-white/90 backdrop-blur">
            <div class="px-4 py-3">
              <h1 class="text-xl font-semibold tracking-tight text-slate-950">Public Booking Share</h1>
              <p class="mt-0.5 text-xs font-medium uppercase tracking-[0.18em] text-slate-400">Open detail post</p>
            </div>
          </div>

          <article class="border-b border-slate-200 px-4 py-4">
            <div class="flex gap-3">
              <div class="flex h-11 w-11 shrink-0 items-center justify-center rounded-full bg-brand-50 text-sm font-semibold text-brand-700 ring-1 ring-brand-100">
                <%= initials(@post.user.name) %>
              </div>

              <div class="min-w-0 flex-1">
                <div class="flex flex-wrap items-center gap-x-2 gap-y-1">
                  <span class="text-sm font-semibold text-slate-950"><%= @post.user.name %></span>
                  <span class="text-sm text-slate-400">@bookable-share</span>
                  <span class="text-sm text-slate-400">·</span>
                  <span class="text-sm text-slate-400"><%= relative_posted_at(@post.inserted_at) %></span>
                  <span class="ml-auto rounded-full bg-success-50 px-2.5 py-1 text-[11px] font-semibold text-success-700 ring-1 ring-success-200">
                    Public
                  </span>
                </div>

                <div class="mt-2 space-y-3">
                  <p class="whitespace-pre-line text-[15px] leading-6 text-slate-800"><%= @post.body %></p>

                  <div class="overflow-hidden rounded-2xl border border-slate-200 bg-white">
                    <div class="border-b border-slate-200 bg-slate-50 px-4 py-3">
                      <div class="flex items-center justify-between gap-3">
                        <div class="text-sm font-semibold text-slate-900">This Week's Booking Window</div>
                        <span class="rounded-full bg-emerald-50 px-2.5 py-1 text-xs font-semibold text-emerald-700">
                          <%= length(@weekly_slots) %> open
                        </span>
                      </div>
                      <p class="mt-2 text-sm leading-6 text-slate-600"><%= @post.booking_note %></p>
                    </div>

                    <div class="space-y-3 px-4 py-3">
                      <div class="text-xs font-semibold uppercase tracking-[0.18em] text-slate-400"><%= target_summary(@post) %></div>
                      <div class="rounded-2xl bg-slate-50 px-3 py-2 text-xs leading-5 text-slate-500">
                        Select a slot below. The booking form stays pinned on the right.
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </article>

           <section class="px-4 py-4">
             <div class="flex items-center justify-between gap-3">
               <h2 class="text-sm font-semibold uppercase tracking-[0.18em] text-slate-400">Available Slots (Next 7 Days)</h2>
               <div class="flex items-center gap-2">
                 <span class="rounded-full bg-slate-100 px-2.5 py-1 text-[11px] font-semibold uppercase tracking-[0.16em] text-slate-500">
                   <%= Social.post_timezone(@post) %>
                 </span>
                 <span class="rounded-full bg-success-50 px-2.5 py-1 text-xs font-semibold text-success-700 ring-1 ring-success-100">
                   <%= length(@weekly_slots) %> open
                 </span>
               </div>
             </div>

            <p :if={@weekly_slots == []} class="mt-4 rounded-2xl border border-dashed border-slate-300 bg-slate-50 px-4 py-6 text-sm text-slate-500">
              No open slots remain for this share right now.
            </p>

            <div :if={@weekly_slots != []} class="mt-4 space-y-2">
              <button
                :for={slot <- @weekly_slots}
                type="button"
                phx-click="select_slot"
                phx-value-slot_id={slot.id}
                class={[
                  "w-full rounded-2xl border px-4 py-3 text-left transition",
                  @selected_slot_id == slot.id &&
                    "border-brand-400 bg-brand-25 ring-2 ring-brand-100",
                  @selected_slot_id != slot.id &&
                    "border-slate-200 bg-white hover:border-slate-300 hover:bg-slate-50"
                ]}
               >
                 <div class="flex flex-wrap items-center justify-between gap-3">
                   <div>
                     <div class="text-sm font-semibold text-slate-950"><%= format_slot_datetime(@post, slot.start_time, slot.end_time) %></div>
                     <div class="mt-1 text-xs text-slate-500"><%= slot_line_item(slot) %> · <%= slot_capacity(slot) %></div>
                   </div>
                   <div class="text-xs font-semibold text-brand-700"><%= slot_price(slot) %></div>
                 </div>
              </button>
            </div>
          </section>
        </main>

        <aside class="px-4 py-4">
           <div class="lg:sticky lg:top-4 lg:space-y-4">
             <div class="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
               <div>
                 <h2 class="text-sm font-semibold uppercase tracking-[0.18em] text-slate-400">Reserve This Time</h2>
                 <p :if={!@selected_slot_id} class="mt-2 text-sm text-slate-500">Choose a slot to continue.</p>
                 <p :if={@selected_slot_id} class="mt-2 text-sm leading-6 text-slate-600"><%= selected_slot_summary(@post, @weekly_slots, @selected_slot_id) %></p>
               </div>

              <.simple_form
                for={@booking_form}
                as={:booking}
                id="public-booking-form"
                phx-submit="book_slot"
              >
                <.input field={@booking_form[:customer_name]} type="text" label="Name" />
                <.input field={@booking_form[:email]} type="email" label="Email" />
                <.input field={@booking_form[:phone]} type="text" label="Phone" />
                <:actions>
                  <.button type="submit" disabled={is_nil(@selected_slot_id)} phx-disable-with="Booking..." class="w-full rounded-full bg-brand-600 hover:bg-brand-500">
                    Confirm Booking
                  </.button>
                </:actions>
              </.simple_form>
            </div>

            <div class="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
              <h2 class="text-sm font-semibold uppercase tracking-[0.18em] text-slate-400">Booking Notes</h2>
              <p class="mt-2 text-sm leading-6 text-slate-600">
                This page only exposes the next 7 days of availability. Remaining capacity updates immediately as bookings are confirmed.
              </p>
            </div>
          </div>
        </aside>
      </div>
    </div>
    """
  end

  def mount(%{"post_id" => post_id}, _session, socket) do
    case Social.get_public_post(post_id) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "That public share is not available.")
         |> push_navigate(to: ~p"/")}

      post ->
        weekly_slots = Social.list_weekly_slots_for_post(post)

        {:ok,
         assign(socket,
           page_title: "Shared Booking",
           post: post,
           weekly_slots: weekly_slots,
           selected_slot_id: default_slot_id(weekly_slots),
           booking_form: booking_form(Map.get(socket.assigns, :current_user))
         )}
    end
  end

  def handle_event("select_slot", %{"slot_id" => slot_id}, socket) do
    {:noreply, assign(socket, :selected_slot_id, slot_id)}
  end

  def handle_event("book_slot", %{"booking" => booking_params}, socket) do
    if is_nil(socket.assigns.selected_slot_id) do
      {:noreply, put_flash(socket, :error, "Select a slot before booking.")}
    else
      attrs =
        booking_params
        |> Map.put("slot_id", socket.assigns.selected_slot_id)
        |> maybe_put_booking_user(Map.get(socket.assigns, :current_user))

      case Social.create_booking_from_post(socket.assigns.post, attrs) do
        {:ok, _booking} ->
          weekly_slots = Social.list_weekly_slots_for_post(socket.assigns.post)

          {:noreply,
           socket
           |> put_flash(:info, "Booking confirmed.")
           |> assign(:weekly_slots, weekly_slots)
           |> assign(:selected_slot_id, default_slot_id(weekly_slots))
           |> assign(:booking_form, booking_form(Map.get(socket.assigns, :current_user)))}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, assign(socket, :booking_form, to_form(Map.put(changeset, :action, :insert), as: :booking))}

        {:error, reason} ->
          {:noreply, put_flash(socket, :error, Social.booking_error_message(reason))}
      end
    end
  end

  defp booking_form(user) do
    to_form(
      %{
        "customer_name" => (user && user.name) || "",
        "email" => (user && user.email) || "",
        "phone" => (user && user.phone) || ""
      },
      as: :booking
    )
  end

  defp default_slot_id([slot | _]), do: slot.id
  defp default_slot_id([]), do: nil

  defp target_summary(post) do
    labels = Enum.reject([post.service && "Service: #{post.service.name}", post.resource && "Resource: #{post.resource.name}"], &is_nil/1)

    Enum.join(labels, " | ")
  end

  defp slot_line_item(slot) do
    labels = Enum.reject([present_label("Service", slot.service_name), present_label("Resource", slot.resource_name)], &is_nil/1)

    Enum.join(labels, " | ")
  end

  defp slot_price(slot) do
    total =
      [slot.service_price, slot.resource_price]
      |> Enum.reject(&is_nil/1)
      |> Enum.reduce(Decimal.new(0), &Decimal.add/2)

    "#{slot.currency || "KRW"} #{Decimal.to_string(total, :normal)}"
  end

  defp selected_slot_summary(post, slots, selected_slot_id) do
    case Enum.find(slots, fn slot -> slot.id == selected_slot_id end) do
      nil -> "Choose a slot to continue."
      slot -> "#{format_slot_datetime(post, slot.start_time, slot.end_time)} | #{slot_line_item(slot)}"
    end
  end

  defp format_slot_datetime(post, start_time, end_time) do
    start_local = Social.post_local_datetime(post, start_time)
    end_local = Social.post_local_datetime(post, end_time)
    start_label = Calendar.strftime(start_local, "%b %d, %a %H:%M")
    end_label = Calendar.strftime(end_local, "%H:%M")
    "#{start_label} - #{end_label} #{start_local.zone_abbr || start_local.time_zone}"
  end

  defp slot_capacity(%{remaining_capacity: nil}), do: "Unlimited"
  defp slot_capacity(%{remaining_capacity: remaining_capacity}), do: "#{remaining_capacity} left"

  defp relative_posted_at(nil), do: "Just now"

  defp relative_posted_at(inserted_at) do
    seconds = DateTime.diff(DateTime.utc_now(), to_datetime(inserted_at), :second)

    cond do
      seconds < 60 -> "Just now"
      seconds < 3_600 -> "#{div(seconds, 60)}m ago"
      seconds < 86_400 -> "#{div(seconds, 3_600)}h ago"
      true -> "#{div(seconds, 86_400)}d ago"
    end
  end

  defp to_datetime(%DateTime{} = value), do: value
  defp to_datetime(%NaiveDateTime{} = value), do: DateTime.from_naive!(value, "Etc/UTC")

  defp initials(name) when is_binary(name) do
    name
    |> String.trim()
    |> String.split(~r/\s+/, trim: true)
    |> Enum.take(2)
    |> Enum.map_join(&String.first/1)
    |> String.upcase()
    |> case do
      "" -> "NA"
      value -> value
    end
  end

  defp initials(_), do: "NA"

  defp maybe_put_booking_user(attrs, %{id: user_id}) when is_binary(user_id), do: Map.put(attrs, "user_id", user_id)
  defp maybe_put_booking_user(attrs, _user), do: attrs

  defp present_label(_label, nil), do: nil
  defp present_label(_label, ""), do: nil
  defp present_label(label, value), do: "#{label}: #{value}"
end
