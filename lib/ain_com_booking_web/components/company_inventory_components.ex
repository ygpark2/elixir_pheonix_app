defmodule AinComBookingWeb.CompanyInventoryComponents do
  @moduledoc false
  use AinComBookingWeb, :html

  import AinComBookingWeb.CompanyConsoleComponents
  import AinComBookingWeb.CompanyInventoryView

  alias AinComBooking.CompanyConsole.BookingPages
  alias Phoenix.LiveView.JS

  attr(:inventory_type, :atom, required: true)
  attr(:inventory, :map, required: true)

  def inventory_card(assigns) do
    ~H"""
    <article
      id={"company-#{inventory_slug(@inventory_type)}-#{@inventory.id}"}
      class="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm"
    >
      <div class="flex flex-wrap items-start justify-between gap-4">
        <div :if={service_inventory?(@inventory_type)} class="min-w-0 flex-1">
          <div class="flex flex-wrap items-center gap-2">
            <h2 class="text-lg font-semibold tracking-tight text-slate-950"><%= @inventory.name %></h2>
            <span class={status_badge_class(@inventory.is_active)}>
              <%= if @inventory.is_active, do: "Active", else: "Paused" %>
            </span>
            <span class={visibility_badge_class(@inventory.is_public)}>
              <%= if @inventory.is_public, do: "Public", else: "Private" %>
            </span>
          </div>
          <p :if={present?(@inventory.description_text)} class="mt-2 text-sm leading-6 text-slate-600"><%= @inventory.description_text %></p>
          <div class="mt-3 flex flex-wrap items-center gap-4 text-xs font-medium text-slate-400">
            <span class="inline-flex items-center gap-1">
              <.icon name="hero-clock" class="h-4 w-4" />
              <%= @inventory.duration %> min
            </span>
            <span class="inline-flex items-center gap-1">
              <.icon name="hero-banknotes" class="h-4 w-4" />
              <%= money(@inventory.price, @inventory.currency) %>
            </span>
          </div>
        </div>

        <div :if={resource_inventory?(@inventory_type)} class="min-w-0 flex-1">
          <div class="flex flex-wrap items-center gap-2">
            <h2 class="text-lg font-semibold tracking-tight text-slate-950"><%= @inventory.name %></h2>
            <span class="rounded-full bg-slate-100 px-2.5 py-1 text-[11px] font-semibold text-slate-600"><%= @inventory.type %></span>
          </div>
          <p :if={present?(@inventory.description)} class="mt-2 text-sm leading-6 text-slate-600"><%= @inventory.description %></p>
          <div class="mt-3 flex flex-wrap items-center gap-4 text-xs font-medium text-slate-400">
            <span class="inline-flex items-center gap-1">
              <.icon name="hero-map-pin" class="h-4 w-4" />
              <%= @inventory.location || "No location" %>
            </span>
            <span class="inline-flex items-center gap-1">
              <.icon name="hero-banknotes" class="h-4 w-4" />
              <%= money(@inventory.price, @inventory.currency) %>
            </span>
          </div>
        </div>

        <div class="flex flex-wrap items-center gap-2">
          <.link patch={inventory_show_path(@inventory_type, @inventory.id)} class={action_link_class()}>View</.link>
          <.link patch={inventory_edit_path(@inventory_type, @inventory.id)} class={action_link_class()}>Edit</.link>
          <.link patch={inventory_delete_path(@inventory_type, @inventory.id)} class={danger_action_link_class()}>Delete</.link>
          <button
            :if={service_inventory?(@inventory_type)}
            type="button"
            phx-click="open_service_bookings_modal"
            phx-value-service_id={@inventory.id}
            class={action_link_class()}
          >
            booked
          </button>
          <button
            :if={resource_inventory?(@inventory_type)}
            type="button"
            phx-click="open_resource_bookings_modal"
            phx-value-resource_id={@inventory.id}
            class={action_link_class()}
          >
            booked
          </button>
        </div>
      </div>
    </article>
    """
  end

  attr(:inventory_type, :atom, required: true)
  attr(:inventory, :map, required: true)

  def inventory_detail_header(assigns) do
    ~H"""
    <article class="rounded-3xl border border-slate-200 bg-white p-6 shadow-sm">
      <div :if={service_inventory?(@inventory_type)} class="flex flex-wrap items-start justify-between gap-4">
        <div class="min-w-0 flex-1">
          <div class="flex flex-wrap items-center gap-2">
            <h2 class="text-2xl font-semibold tracking-tight text-slate-950"><%= @inventory.name %></h2>
            <span class={status_badge_class(@inventory.is_active)}>
              <%= if @inventory.is_active, do: "Active", else: "Paused" %>
            </span>
            <span class={visibility_badge_class(@inventory.is_public)}>
              <%= if @inventory.is_public, do: "Public", else: "Private" %>
            </span>
          </div>
          <p :if={present?(@inventory.description_text)} class="mt-3 text-sm leading-7 text-slate-600"><%= @inventory.description_text %></p>
        </div>

        <div class="flex flex-wrap items-center gap-2">
          <.link patch={inventory_edit_path(@inventory_type, @inventory.id)} class={action_link_class()}>Edit</.link>
          <.link patch={inventory_delete_path(@inventory_type, @inventory.id)} class={danger_action_link_class()}>Delete</.link>
        </div>
      </div>

      <div :if={resource_inventory?(@inventory_type)} class="flex flex-wrap items-start justify-between gap-4">
        <div class="min-w-0 flex-1">
          <div class="flex flex-wrap items-center gap-2">
            <h2 class="text-2xl font-semibold tracking-tight text-slate-950"><%= @inventory.name %></h2>
            <span class="rounded-full bg-slate-100 px-2.5 py-1 text-[11px] font-semibold text-slate-600"><%= @inventory.type %></span>
          </div>
          <p :if={present?(@inventory.description)} class="mt-3 text-sm leading-7 text-slate-600"><%= @inventory.description %></p>
        </div>

        <div class="flex flex-wrap items-center gap-2">
          <.link patch={inventory_edit_path(@inventory_type, @inventory.id)} class={action_link_class()}>Edit</.link>
          <.link patch={inventory_delete_path(@inventory_type, @inventory.id)} class={danger_action_link_class()}>Delete</.link>
        </div>
      </div>

      <dl :if={service_inventory?(@inventory_type)} class="mt-6 grid gap-4 md:grid-cols-2">
        <div class="rounded-2xl bg-slate-50 px-4 py-4">
          <dt class="text-xs font-semibold uppercase tracking-[0.18em] text-slate-400">Duration</dt>
          <dd class="mt-2 text-base font-semibold text-slate-900"><%= @inventory.duration %> minutes</dd>
        </div>
        <div class="rounded-2xl bg-slate-50 px-4 py-4">
          <dt class="text-xs font-semibold uppercase tracking-[0.18em] text-slate-400">Price</dt>
          <dd class="mt-2 text-base font-semibold text-slate-900"><%= money(@inventory.price, @inventory.currency) %></dd>
        </div>
      </dl>

      <dl :if={resource_inventory?(@inventory_type)} class="mt-6 grid gap-4 md:grid-cols-2">
        <div class="rounded-2xl bg-slate-50 px-4 py-4">
          <dt class="text-xs font-semibold uppercase tracking-[0.18em] text-slate-400">Location</dt>
          <dd class="mt-2 text-base font-semibold text-slate-900"><%= @inventory.location || "No location" %></dd>
        </div>
        <div class="rounded-2xl bg-slate-50 px-4 py-4">
          <dt class="text-xs font-semibold uppercase tracking-[0.18em] text-slate-400">Price</dt>
          <dd class="mt-2 text-base font-semibold text-slate-900"><%= money(@inventory.price, @inventory.currency) %></dd>
        </div>
      </dl>
    </article>
    """
  end

  attr(:inventory_type, :atom, required: true)
  attr(:stats, :map, required: true)

  def inventory_snapshot(assigns) do
    ~H"""
    <div class="rounded-3xl border border-slate-200 bg-white p-4 shadow-sm">
      <h2 class="text-lg font-semibold tracking-tight text-slate-950"><%= inventory_snapshot_title(@inventory_type) %></h2>
      <dl class="mt-3 space-y-3">
        <div class="flex items-center justify-between">
          <dt class="text-sm text-slate-500">Total</dt>
          <dd class="text-sm font-semibold text-slate-900"><%= @stats.total %></dd>
        </div>
        <div :if={service_inventory?(@inventory_type)} class="flex items-center justify-between">
          <dt class="text-sm text-slate-500">Active</dt>
          <dd class="text-sm font-semibold text-slate-900"><%= @stats.active %></dd>
        </div>
        <div :if={service_inventory?(@inventory_type)} class="flex items-center justify-between">
          <dt class="text-sm text-slate-500">Public</dt>
          <dd class="text-sm font-semibold text-slate-900"><%= @stats.public %></dd>
        </div>
        <div :if={resource_inventory?(@inventory_type)} class="flex items-center justify-between">
          <dt class="text-sm text-slate-500">With location</dt>
          <dd class="text-sm font-semibold text-slate-900"><%= @stats.located %></dd>
        </div>
        <div :if={resource_inventory?(@inventory_type)} class="flex items-center justify-between">
          <dt class="text-sm text-slate-500">Priced</dt>
          <dd class="text-sm font-semibold text-slate-900"><%= @stats.priced %></dd>
        </div>
      </dl>
    </div>
    """
  end

  attr(:inventory_type, :atom, required: true)
  attr(:booking_pages, :list, required: true)
  attr(:booking_page_form, :any, default: nil)
  attr(:editing_booking_page_id, :any, default: nil)

  def booking_page_section(assigns) do
    ~H"""
    <section class="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
      <div class="flex flex-wrap items-start justify-between gap-3">
        <div>
          <h3 class="text-lg font-semibold tracking-tight text-slate-950">Booking Pages</h3>
          <p class="mt-1 text-sm text-slate-500"><%= inventory_booking_page_description(@inventory_type) %></p>
        </div>
        <span class="rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold uppercase tracking-[0.16em] text-slate-600">
          <%= length(@booking_pages) %> pages
        </span>
      </div>

      <div :if={@booking_pages == []} class="mt-4 rounded-2xl border border-dashed border-slate-300 bg-slate-50 px-4 py-6 text-sm text-slate-500">
        <%= inventory_booking_page_empty_state(@inventory_type) %>
      </div>

      <div :if={@booking_pages != []} class="mt-4 space-y-3">
        <div :for={page <- @booking_pages} class="rounded-2xl border border-slate-200 bg-slate-50 px-4 py-4">
          <div class="flex flex-wrap items-start justify-between gap-3">
            <div class="min-w-0 flex-1">
              <div class="flex flex-wrap items-center gap-2">
                <div class="truncate text-sm font-semibold text-slate-950"><%= page.title %></div>
                <span class={booking_page_status_badge_class(page.is_published)}>
                  <%= if page.is_published, do: "Published", else: "Draft" %>
                </span>
                <span class={booking_page_auto_badge_class(page.auto_slots_enabled)}>
                  <%= if page.auto_slots_enabled, do: "Auto slots", else: "Manual slots" %>
                </span>
              </div>
              <div class="mt-1 truncate text-xs text-slate-400"><%= BookingPages.public_url(page) %></div>
              <p :if={present?(page.description)} class="mt-2 text-sm leading-6 text-slate-600"><%= page.description %></p>
            </div>

            <div class="flex flex-wrap items-center gap-2">
              <.link :if={page.is_published} navigate={BookingPages.public_url(page)} class={action_link_class()}>
                Open
              </.link>
              <button type="button" phx-click="edit_booking_page" phx-value-page_id={page.id} class={action_link_class()}>
                Edit
              </button>
              <button type="button" phx-click="delete_booking_page" phx-value-page_id={page.id} class={danger_action_link_class()}>
                Delete
              </button>
            </div>
          </div>
        </div>
      </div>

      <div class="mt-6 rounded-3xl border border-slate-200 bg-slate-50 p-4">
        <div class="flex flex-wrap items-center justify-between gap-3">
          <div>
            <h4 class="text-sm font-semibold uppercase tracking-[0.18em] text-slate-500">
              <%= if @editing_booking_page_id, do: "Edit Booking Page", else: "New Booking Page" %>
            </h4>
            <p class="mt-1 text-sm text-slate-500">Configure public metadata and optional auto-generated availability windows.</p>
          </div>
          <button
            :if={@editing_booking_page_id}
            type="button"
            phx-click="cancel_booking_page_edit"
            class="inline-flex items-center rounded-full px-3 py-2 text-sm font-medium text-slate-500 transition hover:bg-white hover:text-slate-900"
          >
            New page
          </button>
        </div>

        <.simple_form
          :if={@booking_page_form}
          for={@booking_page_form}
          as={:booking_page}
          id={booking_page_form_id(@inventory_type)}
          phx-change="validate_booking_page"
          phx-submit="save_booking_page"
          class="mt-4"
        >
          <div class="grid gap-4 md:grid-cols-2">
            <.input field={@booking_page_form[:title]} type="text" label="Title" />
            <.input field={@booking_page_form[:slug]} type="text" label="Slug" />
            <.input field={@booking_page_form[:button_label]} type="text" label="Button label" />
            <.input field={@booking_page_form[:theme]} type="text" label="Theme" />
          </div>

          <.input field={@booking_page_form[:description]} type="textarea" rows="4" label="Description" />

          <div class="grid gap-3 md:grid-cols-2">
            <.input field={@booking_page_form[:is_published]} type="checkbox" label="Published" />
            <.input field={@booking_page_form[:auto_slots_enabled]} type="checkbox" label="Auto-generate slots" />
          </div>

          <div class="grid gap-4 md:grid-cols-2">
            <.input field={@booking_page_form[:schedule_start_date]} type="date" label="Schedule start date" />
            <.input field={@booking_page_form[:schedule_end_date]} type="date" label="Schedule end date" />
            <.time_select_input field={@booking_page_form[:work_start_time]} label="Work start time" options={work_time_options()} prompt="Select time" />
            <.time_select_input field={@booking_page_form[:work_end_time]} label="Work end time" options={work_time_options()} prompt="Select time" />
            <.input field={@booking_page_form[:slot_minutes]} type="select" label="Slot length" options={slot_minutes_options()} />
            <.input field={@booking_page_form[:break_minutes]} type="select" label="Break length" options={break_minutes_options()} />
            <.time_select_input field={@booking_page_form[:lunch_start_time]} label="Lunch start" options={work_time_options()} prompt="Optional" />
            <.time_select_input field={@booking_page_form[:lunch_end_time]} label="Lunch end" options={work_time_options()} prompt="Optional" />
            <.input field={@booking_page_form[:default_max_bookings]} type="number" label="Default max bookings" min="1" />
            <.input field={@booking_page_form[:excluded_dates]} type="text" label="Excluded dates" placeholder="2026-05-05, 2026-06-06" />
          </div>

          <.weekday_checkboxes field={@booking_page_form[:available_weekdays]} />

          <:actions>
            <.button type="submit" phx-disable-with="Saving..." class="rounded-full bg-brand-600 px-5 hover:bg-brand-500">
              <%= if @editing_booking_page_id, do: "Save Booking Page", else: "Create Booking Page" %>
            </.button>
            <button
              :if={@editing_booking_page_id}
              type="button"
              phx-click="cancel_booking_page_edit"
              class="rounded-full px-4 py-2 text-sm font-medium text-slate-500 transition hover:bg-white hover:text-slate-900"
            >
              Cancel edit
            </button>
          </:actions>
        </.simple_form>
      </div>
    </section>
    """
  end

  attr(:inventory_type, :atom, required: true)
  attr(:show_bookings_modal, :boolean, required: true)
  attr(:bookings_modal_inventory_name, :string, default: nil)
  attr(:bookings_modal_bookings, :list, required: true)
  attr(:editing_booking_id, :any, default: nil)
  attr(:booking_edit_form, :any, default: nil)
  attr(:booking_status_options, :list, required: true)

  def bookings_modal(assigns) do
    ~H"""
    <.modal
      :if={@show_bookings_modal}
      id={bookings_modal_id(@inventory_type)}
      show={true}
      on_cancel={JS.push("close_bookings_modal")}
    >
      <div class="space-y-4">
        <div class="border-b border-slate-200 px-1 pb-4">
          <p class="text-xs font-semibold uppercase tracking-[0.18em] text-slate-400">booked</p>
          <h2 class="mt-2 pr-8 text-2xl font-semibold tracking-tight text-slate-950"><%= @bookings_modal_inventory_name || inventory_title(@inventory_type) %> 예약 목록</h2>
          <p class="mt-2 text-sm leading-6 text-slate-600">예약 취소와 기본 정보 수정을 이 모달에서 처리할 수 있습니다.</p>
        </div>

        <div :if={@bookings_modal_bookings == []} class="rounded-2xl border border-dashed border-slate-300 bg-slate-50 px-4 py-8 text-sm text-slate-500">
          아직 예약이 없습니다.
        </div>

        <div :if={@bookings_modal_bookings != []} class="max-h-[60vh] space-y-3 overflow-y-auto pr-1">
          <article :for={booking <- @bookings_modal_bookings} class="rounded-2xl border border-slate-200 bg-slate-50 p-4">
            <div class="flex flex-wrap items-start justify-between gap-3">
              <div>
                <div class="flex flex-wrap items-center gap-2">
                  <h3 class="text-sm font-semibold text-slate-950"><%= booking.customer_name %></h3>
                  <span class={booking_status_badge_class(booking.status)}><%= booking.status %></span>
                </div>
                <p class="mt-1 text-xs text-slate-500"><%= booking_slot_window(booking) %></p>
                <p class="mt-2 text-xs text-slate-600"><%= booking.email || "-" %> · <%= booking.phone || "-" %></p>
              </div>
              <div class="flex items-center gap-2">
                <button
                  type="button"
                  phx-click="edit_booking"
                  phx-value-booking_id={booking.id}
                  class={action_link_class()}
                >
                  수정
                </button>
                <button
                  type="button"
                  phx-click="cancel_booking"
                  phx-value-booking_id={booking.id}
                  class={danger_action_link_class()}
                  disabled={booking.status == "cancelled"}
                >
                  예약 취소
                </button>
              </div>
            </div>

            <.simple_form
              :if={@editing_booking_id == booking.id and @booking_edit_form}
              for={@booking_edit_form}
              as={:booking}
              id={"#{inventory_slug(@inventory_type)}-booking-edit-form-#{booking.id}"}
              phx-change="validate_booking"
              phx-submit="save_booking"
              phx-value-booking_id={booking.id}
            >
              <div class="mt-3 grid gap-3 md:grid-cols-2">
                <.input field={@booking_edit_form[:customer_name]} type="text" label="고객명" />
                <.input field={@booking_edit_form[:email]} type="email" label="이메일" />
                <.input field={@booking_edit_form[:phone]} type="text" label="전화번호" />
                <.input field={@booking_edit_form[:status]} type="select" label="상태" options={@booking_status_options} />
              </div>
              <:actions>
                <.button type="submit" phx-disable-with="Saving..." class="rounded-full bg-brand-600 px-4 hover:bg-brand-500">
                  저장
                </.button>
                <button
                  type="button"
                  phx-click="cancel_booking_edit"
                  class="rounded-full px-4 py-2 text-sm font-medium text-slate-500 transition hover:bg-slate-100 hover:text-slate-900"
                >
                  취소
                </button>
              </:actions>
            </.simple_form>
          </article>
        </div>
      </div>
    </.modal>
    """
  end

  attr(:inventory_type, :atom, required: true)
  attr(:calendar_month, :map, required: true)
  attr(:selected_calendar_date, :any, default: nil)
  attr(:selected_calendar_slots, :list, required: true)

  def slot_calendar_section(assigns) do
    ~H"""
    <section class="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
      <div class="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h3 class="text-lg font-semibold tracking-tight text-slate-950"><%= inventory_slot_calendar_title(@inventory_type) %></h3>
          <p class="mt-1 text-sm text-slate-500">Create slots and immediately verify them on the calendar below.</p>
        </div>
        <div class="flex flex-wrap items-center gap-2">
          <button
            type="button"
            phx-click="open_auto_slot_modal"
            class="inline-flex items-center gap-2 rounded-full border border-slate-200 bg-white px-4 py-2 text-sm font-semibold text-slate-700 transition hover:bg-slate-100"
          >
            <.icon name="hero-sparkles" class="h-4 w-4" />
            <span>자동 slot 생성</span>
          </button>
          <button
            type="button"
            phx-click="open_manual_slot_modal"
            class="inline-flex items-center gap-2 rounded-full bg-brand-600 px-4 py-2 text-sm font-semibold text-white transition hover:bg-brand-500"
          >
            <.icon name="hero-plus" class="h-4 w-4" />
            <span>수동 slot 생성</span>
          </button>
        </div>
      </div>

      <div class="mt-4 rounded-3xl border border-slate-200 bg-slate-50 p-4">
        <div class="flex items-center justify-between gap-3">
          <button type="button" phx-click="prev_calendar_month" class={calendar_nav_button_class()}>
            Prev
          </button>
          <div class="text-sm font-semibold tracking-[0.08em] text-slate-950"><%= @calendar_month.label %></div>
          <button type="button" phx-click="next_calendar_month" class={calendar_nav_button_class()}>
            Next
          </button>
        </div>

        <div class="mt-5 grid grid-cols-7 gap-2">
          <div
            :for={label <- @calendar_month.day_headers}
            class="px-2 text-center text-[11px] font-semibold uppercase tracking-[0.18em] text-slate-400"
          >
            <%= label %>
          </div>
        </div>

        <div class="mt-2 space-y-2">
          <div :for={week <- @calendar_month.weeks} class="grid grid-cols-7 gap-2">
            <div
              :for={day <- week}
              class={[
                "min-h-20 rounded-2xl border",
                day.outside_month && "border-transparent bg-transparent",
                !day.outside_month && "border-slate-200 bg-white"
              ]}
            >
              <button
                :if={!day.outside_month}
                type="button"
                phx-click="select_calendar_date"
                phx-value-date={day.iso_date}
                class={calendar_day_button_class(day)}
              >
                <span class={[
                  "text-sm font-semibold",
                  day.is_selected && "text-white",
                  !day.is_selected && "text-slate-900"
                ]}>
                  <%= day.day_number %>
                </span>
                <span class="mt-1 space-y-1">
                  <span class={[
                    "block rounded-full px-1.5 py-0.5 text-[9px] font-semibold ring-1",
                    day.is_selected && "bg-white/10 text-white ring-white/20",
                    !day.is_selected && day.slot_count > 0 && "bg-brand-25 text-brand-700 ring-brand-100",
                    !day.is_selected && day.slot_count == 0 && "bg-white text-slate-400 ring-slate-200"
                  ]}>
                    slot 수 <%= day.slot_count %>
                  </span>
                  <span class={[
                    "block rounded-full px-1.5 py-0.5 text-[9px] font-semibold ring-1",
                    day.is_selected && "bg-white/10 text-white ring-white/20",
                    !day.is_selected && day.booking_count > 0 && "bg-emerald-50 text-emerald-700 ring-emerald-100",
                    !day.is_selected && day.booking_count == 0 && "bg-white text-slate-400 ring-slate-200"
                  ]}>
                    예약 수 <%= day.booking_count %>
                  </span>
                </span>
              </button>
            </div>
          </div>
        </div>
      </div>

      <div class="mt-5 flex items-center justify-between gap-3">
        <h4 class="text-base font-semibold tracking-tight text-slate-950">Selected Day Slots</h4>
        <span class="text-sm font-semibold text-slate-500"><%= selected_date_label(@selected_calendar_date) %></span>
      </div>

      <div :if={@selected_calendar_slots == []} class="mt-3 rounded-2xl border border-dashed border-slate-300 bg-slate-50 px-4 py-6 text-sm text-slate-500">
        No slots on this date.
      </div>

      <div :if={@selected_calendar_slots != []} class="mt-3 space-y-2">
        <div :for={slot <- @selected_calendar_slots} class="rounded-2xl border border-slate-200 bg-white px-4 py-3">
          <div class="flex flex-wrap items-center justify-between gap-2">
            <div>
              <div class="text-sm font-semibold text-slate-950"><%= slot_time_range(slot) %></div>
              <div class="mt-1 text-xs text-slate-500"><%= slot_capacity_label(slot) %> · <%= slot_booking_count_label(slot) %></div>
            </div>
            <div class="flex items-center gap-2">
              <span class={slot_source_badge_class(slot.source_type)}><%= slot_source_label(slot.source_type) %></span>
              <span class={slot_status_badge_class(slot.status)}><%= slot_status_label(slot.status) %></span>
            </div>
          </div>
        </div>
      </div>
    </section>
    """
  end

  attr(:inventory_type, :atom, required: true)
  attr(:show_auto_slot_modal, :boolean, required: true)
  attr(:auto_slot_form, :any, required: true)
  attr(:auto_excluded_date_inputs, :list, required: true)
  attr(:company, :map, required: true)

  def auto_slot_modal(assigns) do
    ~H"""
    <.modal
      :if={@show_auto_slot_modal}
      id={auto_slot_modal_id(@inventory_type)}
      show={true}
      on_cancel={JS.push("close_auto_slot_modal")}
    >
      <div class="space-y-4">
        <div class="border-b border-slate-200 px-1 pb-4">
          <p class="text-xs font-semibold uppercase tracking-[0.18em] text-slate-400">자동 생성</p>
          <h2 class="mt-2 pr-8 text-2xl font-semibold tracking-tight text-slate-950">자동 slot 생성</h2>
          <p class="mt-2 text-sm leading-6 text-slate-600">기간/근무시간 기준으로 다건 slot을 생성합니다.</p>
        </div>

        <.simple_form
          for={@auto_slot_form}
          as={:auto_slot}
          id={auto_slot_form_id(@inventory_type)}
          phx-change="validate_auto_slot"
          phx-submit="create_auto_slots"
        >
          <div class="rounded-2xl border border-slate-200 bg-slate-50 px-4 py-4">
            <div class="text-xs font-semibold uppercase tracking-[0.18em] text-slate-400">Automatic Availability</div>
            <p class="mt-2 text-sm leading-6 text-slate-500">
              Configure recurring working-hour based slots here. Exact one-off slots can be added from this booking page after it is created. Automatic rules use company local time
              (<%= company_timezone_label(@company) %>).
            </p>
          </div>

          <div class="grid gap-4 md:grid-cols-2">
            <.input field={@auto_slot_form[:auto_slots_enabled]} type="checkbox" label="Enable auto-generated slots" />
            <.input field={@auto_slot_form[:default_max_bookings]} type="number" label="Default max bookings per auto slot" min="1" />
            <.input field={@auto_slot_form[:schedule_start_date]} type="date" label="Schedule start date" />
            <.input field={@auto_slot_form[:schedule_end_date]} type="date" label="Schedule end date" />
            <.time_select_input field={@auto_slot_form[:work_start_time]} label="Work start time" prompt="Select start time" options={work_time_options()} />
            <.time_select_input field={@auto_slot_form[:work_end_time]} label="Work end time" prompt="Select end time" options={work_time_options()} />
            <.input field={@auto_slot_form[:slot_minutes]} type="select" label="Slot minutes" options={slot_minutes_options()} />
            <.input field={@auto_slot_form[:break_minutes]} type="select" label="Break minutes" options={break_minutes_options()} />
            <.time_select_input field={@auto_slot_form[:lunch_start_time]} label="Lunch start (optional)" prompt="Select lunch start" options={work_time_options()} />
            <.time_select_input field={@auto_slot_form[:lunch_end_time]} label="Lunch end (optional)" prompt="Select lunch end" options={work_time_options()} />
          </div>

          <.weekday_checkboxes field={@auto_slot_form[:available_weekdays]} />
          <.excluded_date_inputs dates={@auto_excluded_date_inputs} />

          <:actions>
            <.button type="submit" phx-disable-with="Creating..." class="rounded-full bg-brand-600 px-5 hover:bg-brand-500">
              자동 slot 생성
            </.button>
          </:actions>
        </.simple_form>
      </div>
    </.modal>
    """
  end

  attr(:inventory_type, :atom, required: true)
  attr(:show_manual_slot_modal, :boolean, required: true)
  attr(:service_slots, :list, required: true)
  attr(:manual_slot_date, :any, default: nil)
  attr(:manual_slot_max_bookings, :any, default: nil)
  attr(:manual_selected_ranges, :list, required: true)
  attr(:manual_slot_error, :any, default: nil)

  def manual_slot_modal(assigns) do
    assigns = assign(assigns, :hour_stats, manual_hour_stats(assigns.service_slots, assigns.manual_slot_date))

    ~H"""
    <.modal
      :if={@show_manual_slot_modal}
      id={manual_slot_modal_id(@inventory_type)}
      show={true}
      on_cancel={JS.push("close_manual_slot_modal")}
    >
      <div class="space-y-4">
        <div class="border-b border-slate-200 px-1 pb-4">
          <p class="text-xs font-semibold uppercase tracking-[0.18em] text-slate-400">수동 생성</p>
          <h2 class="mt-2 pr-8 text-2xl font-semibold tracking-tight text-slate-950">수동 slot 생성</h2>
          <p class="mt-2 text-sm leading-6 text-slate-600">24시간 타임라인에서 드래그로 시작/종료를 선택하세요. 여러 번 드래그하면 여러 구간을 한 번에 생성할 수 있습니다. 시간 기준은 UTC 입니다.</p>
        </div>

        <form
          id={manual_slot_form_id(@inventory_type)}
          phx-change="validate_manual_slot"
          phx-submit="create_manual_slot"
          class="space-y-4"
        >
          <div class="grid gap-4 md:grid-cols-2">
            <div>
              <.label for={manual_slot_date_input_id(@inventory_type)}>날짜 (UTC)</.label>
              <input
                id={manual_slot_date_input_id(@inventory_type)}
                type="date"
                name="manual_slot[selected_date]"
                value={date_input_value(@manual_slot_date)}
                class="mt-2 block w-full rounded-md border border-gray-300 bg-white shadow-sm focus:border-zinc-400 focus:ring-0 sm:text-sm"
              />
            </div>
            <div>
              <.label for={manual_slot_capacity_input_id(@inventory_type)}>최대 예약 수(선택)</.label>
              <input
                id={manual_slot_capacity_input_id(@inventory_type)}
                type="number"
                min="1"
                name="manual_slot[max_bookings]"
                value={@manual_slot_max_bookings}
                class="mt-2 block w-full rounded-md border border-gray-300 bg-white shadow-sm focus:border-zinc-400 focus:ring-0 sm:text-sm"
              />
            </div>
          </div>

          <div class="rounded-2xl border border-slate-200 bg-slate-50">
            <div class="border-b border-slate-200 px-4 py-3">
              <p class="text-sm font-semibold text-slate-900"><%= selected_date_label(@manual_slot_date) %></p>
              <p class="mt-1 text-xs text-slate-500">타임라인을 드래그해서 구간을 선택하세요. 가장 아래까지 선택하면 다음날 00:00까지 확장됩니다.</p>
            </div>

            <div
              id={manual_slot_drag_grid_id(@inventory_type)}
              phx-hook="ManualSlotDragSelector"
              data-select-event="manual_drag_select"
              class="max-h-[48vh] overflow-y-auto bg-white select-none"
            >
              <div
                :for={segment <- manual_time_segments()}
                data-slot-index={segment.index}
                class={[
                  "flex min-h-6 items-center border-b border-slate-200 px-3 py-1 transition cursor-row-resize last:border-b-0",
                  manual_segment_selected?(@manual_selected_ranges, segment.index) && "bg-brand-100",
                  !manual_segment_selected?(@manual_selected_ranges, segment.index) && "hover:bg-slate-50"
                ]}
              >
                <div class={[
                  "w-14 shrink-0 text-[11px] font-semibold",
                  segment.minute == 0 && "text-slate-600",
                  segment.minute != 0 && "text-slate-300"
                ]}>
                  <%= segment.label %>
                </div>
                <div class="flex min-h-5 flex-1 items-center justify-between border-l border-slate-200 pl-3">
                  <span class="text-[11px] text-slate-400"><%= manual_segment_minute_label(segment.minute) %></span>
                  <span :if={segment.minute == 0} class="text-[10px] font-medium text-slate-400">
                    slot 수 <%= hour_slot_count(@hour_stats, segment.hour) %> · 예약 수 <%= hour_booking_count(@hour_stats, segment.hour) %>
                  </span>
                </div>
              </div>
            </div>
          </div>

          <div class="rounded-2xl border border-slate-200 bg-white p-3">
            <div class="flex items-center justify-between gap-3">
              <p class="text-sm font-semibold text-slate-900">선택된 시간 구간</p>
              <button
                type="button"
                phx-click="clear_manual_drag_ranges"
                class="rounded-full px-3 py-1 text-xs font-semibold text-slate-500 transition hover:bg-slate-100 hover:text-slate-900"
                disabled={@manual_selected_ranges == []}
              >
                전체 지우기
              </button>
            </div>
            <p :if={@manual_selected_ranges == []} class="mt-2 text-xs text-slate-500">아직 선택된 구간이 없습니다. 타임라인에서 드래그해 주세요.</p>
            <div :if={@manual_selected_ranges != []} class="mt-2 space-y-2">
              <div
                :for={{range, index} <- Enum.with_index(@manual_selected_ranges)}
                class="flex items-center justify-between gap-3 rounded-xl border border-slate-200 bg-slate-50 px-3 py-2"
              >
                <span class="text-xs font-semibold text-slate-700"><%= manual_slot_range_label(range) %></span>
                <button
                  type="button"
                  phx-click="remove_manual_drag_range"
                  phx-value-index={index}
                  class="rounded-full px-2.5 py-1 text-xs font-semibold text-danger-700 transition hover:bg-danger-50"
                >
                  삭제
                </button>
              </div>
            </div>
          </div>

          <p :if={present?(@manual_slot_error)} class="text-sm font-medium text-danger-700"><%= @manual_slot_error %></p>

          <div class="flex items-center justify-end pt-2">
            <.button type="submit" phx-disable-with="Creating..." class="rounded-full bg-brand-600 px-5 hover:bg-brand-500">
              선택 구간 slot 생성
            </.button>
          </div>
        </form>
      </div>
    </.modal>
    """
  end

  attr(:dates, :list, default: [""])

  def excluded_date_inputs(assigns) do
    assigns =
      assign(
        assigns,
        :show_remove,
        length(assigns.dates) > 1 or Enum.any?(assigns.dates, &(&1 != ""))
      )

    ~H"""
    <div class="md:col-span-2">
      <div class="flex flex-wrap items-center justify-between gap-3">
        <div>
          <.label for="auto-excluded-date-0">Excluded dates</.label>
          <p class="mt-1 text-xs text-slate-400">Pick specific holidays or blocked dates. Leave blank if not needed.</p>
        </div>
        <button
          type="button"
          phx-click="add_auto_excluded_date"
          class="inline-flex items-center rounded-full px-3 py-2 text-sm font-medium text-slate-500 transition hover:bg-slate-100 hover:text-slate-900"
        >
          Add date
        </button>
      </div>

      <div class="mt-3 space-y-3">
        <div :for={{date, index} <- Enum.with_index(@dates)} class="flex items-center gap-3">
          <div class="relative min-w-0 flex-1">
            <input type="hidden" :if={index == 0} name="auto_slot[excluded_dates][]" value="" />
            <input
              id={"auto-excluded-date-#{index}"}
              type="date"
              name="auto_slot[excluded_dates][]"
              value={date}
              class="block w-full rounded-lg border border-zinc-300 bg-white pr-11 text-zinc-900 focus:border-zinc-400 focus:ring-0 sm:text-sm sm:leading-6"
            />
            <.icon name="hero-calendar-days" class="pointer-events-none absolute right-3 top-1/2 h-5 w-5 -translate-y-1/2 text-slate-400" />
          </div>
          <button
            :if={@show_remove}
            type="button"
            phx-click="remove_auto_excluded_date"
            phx-value-index={index}
            class="inline-flex items-center rounded-full px-3 py-2 text-sm font-medium text-danger-700 transition hover:bg-danger-50"
          >
            Remove
          </button>
        </div>
      </div>
    </div>
    """
  end

  defp action_link_class do
    "inline-flex items-center rounded-full px-3 py-2 text-sm font-medium text-slate-500 transition hover:bg-slate-100 hover:text-slate-900"
  end

  defp danger_action_link_class do
    "inline-flex items-center rounded-full px-3 py-2 text-sm font-medium text-danger-700 transition hover:bg-danger-50"
  end

  defp status_badge_class(true), do: "rounded-full bg-emerald-50 px-2.5 py-1 text-[11px] font-semibold text-emerald-700"
  defp status_badge_class(false), do: "rounded-full bg-slate-100 px-2.5 py-1 text-[11px] font-semibold text-slate-500"

  defp visibility_badge_class(true), do: "rounded-full bg-brand-50 px-2.5 py-1 text-[11px] font-semibold text-brand-700"
  defp visibility_badge_class(false), do: "rounded-full bg-slate-100 px-2.5 py-1 text-[11px] font-semibold text-slate-500"

  defp money(nil, currency), do: "0 #{currency || "KRW"}"
  defp money(price, currency), do: "#{price} #{currency}"

  defp present?(value), do: value not in [nil, ""]
  defp company_timezone_label(%{timezone: timezone}) when is_binary(timezone) and timezone != "", do: timezone
  defp company_timezone_label(_company), do: "Asia/Seoul"
end
