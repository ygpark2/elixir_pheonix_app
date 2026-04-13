defmodule AinComBookingWeb.CompanyResourceLive do
  @moduledoc false
  use AinComBookingWeb, :live_view

  import AinComBookingWeb.CompanyConsoleComponents

  alias AinComBooking.Bookings.CompanyBooking
  alias AinComBooking.Catalog.CompanyResource
  alias AinComBooking.CompanyConsole
  alias Phoenix.LiveView.JS

  @resource_type_options [
    {"Room", "room"},
    {"Equipment", "equipment"},
    {"Desk", "desk"},
    {"Studio", "studio"}
  ]

  @default_manual_slot_minutes 30
  @manual_drag_step_minutes 15
  @default_auto_slot_days 7
  @calendar_day_headers ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
  @weekday_to_number %{
    "mon" => 1,
    "tue" => 2,
    "wed" => 3,
    "thu" => 4,
    "fri" => 5,
    "sat" => 6,
    "sun" => 7
  }
  @slot_minutes_options [
    {"15 minutes", 15},
    {"30 minutes", 30},
    {"45 minutes", 45},
    {"60 minutes", 60},
    {"90 minutes", 90},
    {"120 minutes", 120}
  ]
  @break_minutes_options [
    {"0 minutes", 0},
    {"5 minutes", 5},
    {"10 minutes", 10},
    {"15 minutes", 15},
    {"20 minutes", 20},
    {"30 minutes", 30},
    {"45 minutes", 45},
    {"60 minutes", 60}
  ]
  @weekday_options [
    {"Mon", "mon"},
    {"Tue", "tue"},
    {"Wed", "wed"},
    {"Thu", "thu"},
    {"Fri", "fri"},
    {"Sat", "sat"},
    {"Sun", "sun"}
  ]
  @weekday_values Enum.map(@weekday_options, &elem(&1, 1))
  @booking_status_options [
    {"Confirmed", "confirmed"},
    {"Cancelled", "cancelled"},
    {"No-show", "noshow"}
  ]
  @work_time_options (for slot <- 0..47 do
                        hour =
                          slot
                          |> div(2)
                          |> Integer.to_string()
                          |> String.pad_leading(2, "0")

                        minute =
                          slot
                          |> rem(2)
                          |> Kernel.*(30)
                          |> Integer.to_string()
                          |> String.pad_leading(2, "0")

                        label = "#{hour}:#{minute}"
                        {label, label}
                      end)

  def render(assigns) do
    ~H"""
    <.shell
      current_user={@current_user}
      company={@company}
      active_section={:resources}
      page_title={@page_title}
      page_label={resource_page_label(@live_action)}
      page_subtitle="Resources are your bookable inventory. Configure manual and automatic slots directly from each resource detail page."
    >
      <div class="space-y-5">
        <div :if={@live_action == :index} class="flex justify-end">
          <.link
            patch={~p"/company/console/resources/new"}
            class="inline-flex items-center gap-2 rounded-full bg-brand-600 px-4 py-2 text-sm font-semibold text-white transition hover:bg-brand-500"
          >
            <.icon name="hero-plus" class="h-4 w-4" />
            <span>New Resource</span>
          </.link>
        </div>

        <section :if={@live_action == :index} class="space-y-4">
          <div :if={@resources == []} class="rounded-3xl border border-dashed border-slate-300 bg-slate-50 px-6 py-10 text-center text-sm text-slate-500">
            No company resources yet. Add one so customers can book rooms, equipment, or desks.
          </div>

          <article
            :for={resource <- @resources}
            id={"company-resource-#{resource.id}"}
            class="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm"
          >
            <div class="flex flex-wrap items-start justify-between gap-4">
              <div class="min-w-0 flex-1">
                <div class="flex flex-wrap items-center gap-2">
                  <h2 class="text-lg font-semibold tracking-tight text-slate-950"><%= resource.name %></h2>
                  <span class="rounded-full bg-slate-100 px-2.5 py-1 text-[11px] font-semibold text-slate-600"><%= resource.type %></span>
                </div>
                <p :if={present?(resource.description)} class="mt-2 text-sm leading-6 text-slate-600"><%= resource.description %></p>
                <div class="mt-3 flex flex-wrap items-center gap-4 text-xs font-medium text-slate-400">
                  <span class="inline-flex items-center gap-1">
                    <.icon name="hero-map-pin" class="h-4 w-4" />
                    <%= resource.location || "No location" %>
                  </span>
                  <span class="inline-flex items-center gap-1">
                    <.icon name="hero-banknotes" class="h-4 w-4" />
                    <%= money(resource.price, resource.currency) %>
                  </span>
                </div>
              </div>

              <div class="flex flex-wrap items-center gap-2">
                <.link patch={~p"/company/console/resources/#{resource.id}"} class={action_link_class()}>View</.link>
                <.link patch={~p"/company/console/resources/#{resource.id}/edit"} class={action_link_class()}>Edit</.link>
                <.link patch={~p"/company/console/resources/#{resource.id}/delete"} class={danger_action_link_class()}>Delete</.link>
                <button
                  type="button"
                  phx-click="open_resource_bookings_modal"
                  phx-value-resource_id={resource.id}
                  class={action_link_class()}
                >
                  booked
                </button>
              </div>
            </div>
          </article>
        </section>

        <section :if={@live_action == :new or @live_action == :edit} class="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
          <.simple_form for={@form} as={:resource} id="company-resource-form" phx-change="validate" phx-submit="save">
            <div class="grid gap-4 md:grid-cols-2">
              <.input field={@form[:name]} type="text" label="Name" />
              <.input field={@form[:type]} type="select" label="Type" options={@resource_type_options} prompt="Choose a type" />
              <.input field={@form[:location]} type="text" label="Location" />
              <.input field={@form[:currency]} type="text" label="Currency" />
              <.input field={@form[:price]} type="number" label="Price" step="0.01" min="0" />
            </div>

            <.input field={@form[:description]} type="textarea" rows="4" label="Description" />

            <:actions>
              <.button type="submit" phx-disable-with="Saving..." class="rounded-full bg-brand-600 px-5 hover:bg-brand-500">
                <%= if @live_action == :new, do: "Create Resource", else: "Save Changes" %>
              </.button>
              <.link patch={cancel_resource_path(@resource)} class="rounded-full px-4 py-2 text-sm font-medium text-slate-500 transition hover:bg-slate-100 hover:text-slate-900">
                Cancel
              </.link>
            </:actions>
          </.simple_form>
        </section>

        <section :if={@live_action == :show and @resource} class="space-y-4">
          <article class="rounded-3xl border border-slate-200 bg-white p-6 shadow-sm">
            <div class="flex flex-wrap items-start justify-between gap-4">
              <div class="min-w-0 flex-1">
                <div class="flex flex-wrap items-center gap-2">
                  <h2 class="text-2xl font-semibold tracking-tight text-slate-950"><%= @resource.name %></h2>
                  <span class="rounded-full bg-slate-100 px-2.5 py-1 text-[11px] font-semibold text-slate-600"><%= @resource.type %></span>
                </div>
                <p :if={present?(@resource.description)} class="mt-3 text-sm leading-7 text-slate-600"><%= @resource.description %></p>
              </div>

              <div class="flex flex-wrap items-center gap-2">
                <.link patch={~p"/company/console/resources/#{@resource.id}/edit"} class={action_link_class()}>Edit</.link>
                <.link patch={~p"/company/console/resources/#{@resource.id}/delete"} class={danger_action_link_class()}>Delete</.link>
              </div>
            </div>

            <dl class="mt-6 grid gap-4 md:grid-cols-2">
              <div class="rounded-2xl bg-slate-50 px-4 py-4">
                <dt class="text-xs font-semibold uppercase tracking-[0.18em] text-slate-400">Location</dt>
                <dd class="mt-2 text-base font-semibold text-slate-900"><%= @resource.location || "No location" %></dd>
              </div>
              <div class="rounded-2xl bg-slate-50 px-4 py-4">
                <dt class="text-xs font-semibold uppercase tracking-[0.18em] text-slate-400">Price</dt>
                <dd class="mt-2 text-base font-semibold text-slate-900"><%= money(@resource.price, @resource.currency) %></dd>
              </div>
            </dl>
          </article>

          <section class="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
            <div class="flex flex-wrap items-center justify-between gap-3">
              <div>
                <h3 class="text-lg font-semibold tracking-tight text-slate-950">Resource Slot Calendar</h3>
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

          <.modal
            :if={@show_auto_slot_modal}
            id="resource-auto-slot-modal"
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
                id="resource-auto-slot-form"
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
                  <.time_select_input
                    field={@auto_slot_form[:lunch_start_time]}
                    label="Lunch start (optional)"
                    prompt="Select lunch start"
                    options={work_time_options()}
                  />
                  <.time_select_input
                    field={@auto_slot_form[:lunch_end_time]}
                    label="Lunch end (optional)"
                    prompt="Select lunch end"
                    options={work_time_options()}
                  />
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

          <.modal
            :if={@show_manual_slot_modal}
            id="resource-manual-slot-modal"
            show={true}
            on_cancel={JS.push("close_manual_slot_modal")}
          >
            <% hour_stats = manual_hour_stats(@resource_slots, @manual_slot_date) %>
            <div class="space-y-4">
              <div class="border-b border-slate-200 px-1 pb-4">
                <p class="text-xs font-semibold uppercase tracking-[0.18em] text-slate-400">수동 생성</p>
                <h2 class="mt-2 pr-8 text-2xl font-semibold tracking-tight text-slate-950">수동 slot 생성</h2>
                <p class="mt-2 text-sm leading-6 text-slate-600">24시간 타임라인에서 드래그로 시작/종료를 선택하세요. 여러 번 드래그하면 여러 구간을 한 번에 생성할 수 있습니다. 시간 기준은 UTC 입니다.</p>
              </div>

              <form
                id="resource-manual-slot-form"
                phx-change="validate_manual_slot"
                phx-submit="create_manual_slot"
                class="space-y-4"
              >
                <div class="grid gap-4 md:grid-cols-2">
                  <div>
                    <.label for="resource-manual-slot-date">날짜 (UTC)</.label>
                    <input
                      id="resource-manual-slot-date"
                      type="date"
                      name="manual_slot[selected_date]"
                      value={date_input_value(@manual_slot_date)}
                      class="mt-2 block w-full rounded-md border border-gray-300 bg-white shadow-sm focus:border-zinc-400 focus:ring-0 sm:text-sm"
                    />
                  </div>
                  <div>
                    <.label for="resource-manual-slot-max-bookings">최대 예약 수(선택)</.label>
                    <input
                      id="resource-manual-slot-max-bookings"
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
                    id="resource-manual-slot-drag-grid"
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
                          slot 수 <%= hour_slot_count(hour_stats, segment.hour) %> · 예약 수 <%= hour_booking_count(hour_stats, segment.hour) %>
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
        </section>

        <section :if={@live_action == :delete and @resource} class="rounded-3xl border border-danger-200 bg-danger-25 p-6 shadow-sm">
          <p class="text-xs font-semibold uppercase tracking-[0.18em] text-danger-700">Delete Resource</p>
          <h2 class="mt-2 text-2xl font-semibold tracking-tight text-slate-950"><%= @resource.name %></h2>
          <p class="mt-3 text-sm leading-6 text-slate-600">
            This also removes any company slots and booking pages linked to this resource.
          </p>

          <div class="mt-5 flex flex-wrap items-center gap-3">
            <button
              type="button"
              phx-click="confirm_delete"
              class="inline-flex items-center gap-2 rounded-full bg-danger-600 px-5 py-2 text-sm font-semibold text-white transition hover:bg-danger-500"
            >
              <.icon name="hero-trash" class="h-4 w-4" />
              <span>Delete Resource</span>
            </button>
            <.link patch={~p"/company/console/resources/#{@resource.id}"} class="rounded-full px-4 py-2 text-sm font-medium text-slate-500 transition hover:bg-white hover:text-slate-900">
              Cancel
            </.link>
          </div>
        </section>
      </div>

      <.modal
        :if={@show_bookings_modal}
        id="resource-bookings-modal"
        show={true}
        on_cancel={JS.push("close_bookings_modal")}
      >
        <div class="space-y-4">
          <div class="border-b border-slate-200 px-1 pb-4">
            <p class="text-xs font-semibold uppercase tracking-[0.18em] text-slate-400">booked</p>
            <h2 class="mt-2 pr-8 text-2xl font-semibold tracking-tight text-slate-950"><%= @bookings_modal_resource_name || "Resource" %> 예약 목록</h2>
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
                id={"resource-booking-edit-form-#{booking.id}"}
                phx-change="validate_booking"
                phx-submit="save_booking"
                phx-value-booking_id={booking.id}
              >
                <div class="mt-3 grid gap-3 md:grid-cols-2">
                  <.input field={@booking_edit_form[:customer_name]} type="text" label="고객명" />
                  <.input field={@booking_edit_form[:email]} type="email" label="이메일" />
                  <.input field={@booking_edit_form[:phone]} type="text" label="전화번호" />
                  <.input field={@booking_edit_form[:status]} type="select" label="상태" options={booking_status_options()} />
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

      <:sidebar>
        <div class="space-y-4">
          <div class="rounded-3xl border border-slate-200 bg-white p-4 shadow-sm">
            <h2 class="text-lg font-semibold tracking-tight text-slate-950">Resource Snapshot</h2>
            <dl class="mt-3 space-y-3">
              <div class="flex items-center justify-between">
                <dt class="text-sm text-slate-500">Total</dt>
                <dd class="text-sm font-semibold text-slate-900"><%= @stats.total %></dd>
              </div>
              <div class="flex items-center justify-between">
                <dt class="text-sm text-slate-500">With location</dt>
                <dd class="text-sm font-semibold text-slate-900"><%= @stats.located %></dd>
              </div>
              <div class="flex items-center justify-between">
                <dt class="text-sm text-slate-500">Priced</dt>
                <dd class="text-sm font-semibold text-slate-900"><%= @stats.priced %></dd>
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
     |> assign(:resource_type_options, @resource_type_options)
     |> assign(:resource, nil)
     |> assign(:form, nil)
     |> assign(:resources, [])
     |> assign(:resource_slots, [])
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
     |> assign(:bookings_modal_resource_id, nil)
     |> assign(:bookings_modal_resource_name, nil)
     |> assign(:bookings_modal_bookings, [])
     |> assign(:editing_booking_id, nil)
     |> assign(:booking_edit_form, nil)
     |> assign(:stats, %{total: 0, located: 0, priced: 0})
     |> assign(:page_title, "Company Resources")}
  end

  def handle_params(params, _uri, socket) do
    resources = CompanyConsole.list_company_resources(socket.assigns.current_user)

    socket =
      socket
      |> assign(:resources, resources)
      |> assign(:stats, resource_stats(resources))

    case socket.assigns.live_action do
      :index ->
        {:noreply,
         socket
         |> assign(:page_title, "Company Resources")
         |> assign(:resource, nil)
         |> assign(:form, nil)
         |> clear_slot_state()}

      :new ->
        {:noreply,
         socket
         |> assign(:page_title, "Create Company Resource")
         |> assign(:resource, nil)
         |> assign(:form, to_form(default_resource_changeset(socket.assigns.current_user), as: :resource))
         |> clear_slot_state()}

      action ->
        load_resource(socket, params["id"], action)
    end
  end

  def handle_event("validate", %{"resource" => params}, socket) do
    changeset =
      socket
      |> resource_changeset_for_action(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset, as: :resource))}
  end

  def handle_event("save", %{"resource" => params}, socket) do
    case socket.assigns.live_action do
      :new ->
        case CompanyConsole.create_company_resource(socket.assigns.current_user, params) do
          {:ok, resource} ->
            {:noreply,
             socket
             |> put_flash(:info, "Company resource created.")
             |> push_patch(to: ~p"/company/console/resources/#{resource.id}")}

          {:error, changeset} ->
            {:noreply, assign(socket, :form, to_form(Map.put(changeset, :action, :insert), as: :resource))}
        end

      :edit ->
        case CompanyConsole.update_company_resource(socket.assigns.resource, params) do
          {:ok, resource} ->
            {:noreply,
             socket
             |> put_flash(:info, "Company resource updated.")
             |> push_patch(to: ~p"/company/console/resources/#{resource.id}")}

          {:error, changeset} ->
            {:noreply, assign(socket, :form, to_form(Map.put(changeset, :action, :update), as: :resource))}
        end
    end
  end

  def handle_event("open_resource_bookings_modal", %{"resource_id" => resource_id}, socket) do
    case CompanyConsole.get_company_resource(socket.assigns.current_user, resource_id) do
      %CompanyResource{} = resource ->
        {:noreply,
         socket
         |> assign(:show_bookings_modal, true)
         |> assign(:bookings_modal_resource_id, resource.id)
         |> assign(:bookings_modal_resource_name, resource.name)
         |> assign(:bookings_modal_bookings, CompanyConsole.list_company_bookings_for_resource(socket.assigns.current_user, resource.id))
         |> assign(:editing_booking_id, nil)
         |> assign(:booking_edit_form, nil)}

      _ ->
        {:noreply, put_flash(socket, :error, "리소스를 찾을 수 없습니다.")}
    end
  end

  def handle_event("close_bookings_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_bookings_modal, false)
     |> assign(:editing_booking_id, nil)
     |> assign(:booking_edit_form, nil)}
  end

  def handle_event("edit_booking", %{"booking_id" => booking_id}, socket) do
    case fetch_resource_booking(socket, booking_id) do
      {:ok, booking} ->
        {:noreply,
         socket
         |> assign(:editing_booking_id, booking.id)
         |> assign(:booking_edit_form, to_form(CompanyConsole.change_company_booking(booking), as: :booking))}

      _ ->
        {:noreply, put_flash(socket, :error, "예약을 찾을 수 없습니다.")}
    end
  end

  def handle_event("cancel_booking_edit", _params, socket) do
    {:noreply,
     socket
     |> assign(:editing_booking_id, nil)
     |> assign(:booking_edit_form, nil)}
  end

  def handle_event("cancel_booking", %{"booking_id" => booking_id}, socket) do
    with {:ok, booking} <- fetch_resource_booking(socket, booking_id),
         {:ok, _updated_booking} <- CompanyConsole.update_company_booking(socket.assigns.current_user, booking, %{"status" => "cancelled"}) do
      {:noreply,
       socket
       |> refresh_resource_bookings_modal()
       |> maybe_refresh_resource_slot_calendar()
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

  def handle_event("validate_booking", %{"booking_id" => booking_id, "booking" => params}, socket) do
    case fetch_resource_booking(socket, booking_id) do
      {:ok, booking} ->
        changeset =
          booking
          |> CompanyConsole.change_company_booking(params)
          |> Map.put(:action, :validate)

        {:noreply,
         socket
         |> assign(:editing_booking_id, booking.id)
         |> assign(:booking_edit_form, to_form(changeset, as: :booking))}

      _ ->
        {:noreply, put_flash(socket, :error, "예약을 찾을 수 없습니다.")}
    end
  end

  def handle_event("save_booking", %{"booking_id" => booking_id, "booking" => params}, socket) do
    case fetch_resource_booking(socket, booking_id) do
      {:ok, booking} ->
        case CompanyConsole.update_company_booking(socket.assigns.current_user, booking, params) do
          {:ok, _updated_booking} ->
            {:noreply,
             socket
             |> refresh_resource_bookings_modal()
             |> maybe_refresh_resource_slot_calendar()
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

  def handle_event("open_manual_slot_modal", _params, socket) do
    selected_date = socket.assigns.selected_calendar_date || Date.utc_today()

    {:noreply,
     socket
     |> assign(:manual_slot_date, selected_date)
     |> assign(:manual_selected_ranges, [])
     |> assign(:manual_slot_max_bookings, "")
     |> assign(:manual_slot_error, nil)
     |> assign(:show_manual_slot_modal, true)}
  end

  def handle_event("close_manual_slot_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_manual_slot_modal, false)
     |> assign(:manual_slot_error, nil)}
  end

  def handle_event("manual_drag_select", %{"start_index" => start_index, "end_index" => end_index}, socket) do
    max_slots = manual_slot_index_limit()

    with {:ok, parsed_start} <- parse_manual_slot_index(start_index, 0, max_slots - 1),
         {:ok, parsed_end} <- parse_manual_slot_index(end_index, 1, max_slots),
         true <- parsed_end > parsed_start do
      ranges =
        socket.assigns.manual_selected_ranges
        |> Kernel.++([%{start_index: parsed_start, end_index: parsed_end}])
        |> normalize_manual_slot_ranges()

      {:noreply,
       socket
       |> assign(:manual_selected_ranges, ranges)
       |> assign(:manual_slot_error, nil)}
    else
      _ -> {:noreply, socket}
    end
  end

  def handle_event("clear_manual_drag_ranges", _params, socket) do
    {:noreply,
     socket
     |> assign(:manual_selected_ranges, [])
     |> assign(:manual_slot_error, nil)}
  end

  def handle_event("remove_manual_drag_range", %{"index" => index}, socket) do
    ranges = remove_manual_slot_range(socket.assigns.manual_selected_ranges, index)

    {:noreply,
     socket
     |> assign(:manual_selected_ranges, ranges)
     |> assign(:manual_slot_error, nil)}
  end

  def handle_event("validate_manual_slot", %{"manual_slot" => params}, socket) do
    selected_date = parse_manual_slot_date(params["selected_date"], socket.assigns.manual_slot_date || Date.utc_today())
    selected_ranges = if selected_date == socket.assigns.manual_slot_date, do: socket.assigns.manual_selected_ranges, else: []

    {:noreply,
     socket
     |> assign(:manual_slot_date, selected_date)
     |> assign(:manual_selected_ranges, selected_ranges)
     |> assign(:manual_slot_max_bookings, normalize_manual_slot_max_bookings(params["max_bookings"]))
     |> assign(:manual_slot_error, nil)}
  end

  def handle_event("create_manual_slot", %{"manual_slot" => params}, socket) do
    selected_date = parse_manual_slot_date(params["selected_date"], socket.assigns.manual_slot_date || Date.utc_today())
    selected_ranges = if selected_date == socket.assigns.manual_slot_date, do: socket.assigns.manual_selected_ranges, else: []

    with {:ok, max_bookings} <- parse_manual_slot_max_bookings(params["max_bookings"]),
         true <- selected_ranges != [],
         {:ok, day_start} <- DateTime.new(selected_date, ~T[00:00:00], "Etc/UTC") do
      existing_keys = MapSet.new(socket.assigns.resource_slots, &slot_window_key(&1.start_time, &1.end_time))

      {created_count, skipped_count} =
        selected_ranges
        |> Enum.reduce({0, 0, existing_keys}, fn range, {created, skipped, seen_keys} ->
          start_time = manual_slot_datetime(day_start, range.start_index)
          end_time = manual_slot_datetime(day_start, range.end_index)
          window_key = slot_window_key(start_time, end_time)

          if MapSet.member?(seen_keys, window_key) do
            {created, skipped + 1, seen_keys}
          else
            attrs =
              manual_slot_attrs(socket.assigns.resource, %{
                "start_time" => start_time,
                "end_time" => end_time,
                "max_bookings" => max_bookings
              })

            case CompanyConsole.create_company_slot(socket.assigns.current_user, attrs) do
              {:ok, _slot} -> {created + 1, skipped, MapSet.put(seen_keys, window_key)}
              {:error, _changeset} -> {created, skipped + 1, seen_keys}
            end
          end
        end)
        |> then(fn {created, skipped, _seen_keys} -> {created, skipped} end)

      flash_type = if created_count > 0, do: :info, else: :error
      selected_ranges_after_create = if created_count > 0, do: [], else: selected_ranges

      {:noreply,
       socket
       |> put_flash(flash_type, manual_slot_result_message(created_count, skipped_count))
       |> assign(:show_manual_slot_modal, created_count == 0)
       |> assign(:manual_slot_date, selected_date)
       |> assign(:manual_selected_ranges, selected_ranges_after_create)
       |> assign(:manual_slot_max_bookings, normalize_manual_slot_max_bookings(params["max_bookings"]))
       |> assign(:manual_slot_error, nil)
       |> assign_resource_slot_state(socket.assigns.resource,
         selected_date: selected_date,
         visible_month: month_start(selected_date)
       )}
    else
      false ->
        {:noreply,
         socket
         |> assign(:manual_slot_date, selected_date)
         |> assign(:manual_selected_ranges, selected_ranges)
         |> assign(:manual_slot_max_bookings, normalize_manual_slot_max_bookings(params["max_bookings"]))
         |> assign(:manual_slot_error, "드래그로 시간 구간을 1개 이상 선택해 주세요.")}

      {:error, :invalid_max_bookings} ->
        {:noreply,
         socket
         |> assign(:manual_slot_date, selected_date)
         |> assign(:manual_selected_ranges, selected_ranges)
         |> assign(:manual_slot_max_bookings, normalize_manual_slot_max_bookings(params["max_bookings"]))
         |> assign(:manual_slot_error, "최대 예약 수는 1 이상의 숫자여야 합니다.")}

      _ ->
        {:noreply,
         socket
         |> assign(:manual_slot_date, selected_date)
         |> assign(:manual_selected_ranges, selected_ranges)
         |> assign(:manual_slot_max_bookings, normalize_manual_slot_max_bookings(params["max_bookings"]))
         |> assign(:manual_slot_error, "선택한 날짜를 처리할 수 없습니다.")}
    end
  end

  def handle_event("open_auto_slot_modal", _params, socket) do
    changeset = (socket.assigns.auto_slot_form && socket.assigns.auto_slot_form.source) || default_auto_slot_changeset()
    form = to_form(changeset, as: :auto_slot)
    excluded_date_inputs = excluded_date_inputs_from_changeset(changeset)

    {:noreply,
     socket
     |> assign(:auto_slot_form, form)
     |> assign(:auto_excluded_date_inputs, excluded_date_inputs)
     |> assign(:show_auto_slot_modal, true)}
  end

  def handle_event("close_auto_slot_modal", _params, socket) do
    {:noreply, assign(socket, :show_auto_slot_modal, false)}
  end

  def handle_event("validate_auto_slot", %{"auto_slot" => params}, socket) do
    excluded_date_inputs = excluded_date_inputs_from_params(params)
    normalized_params = normalize_auto_slot_params(params)

    changeset =
      normalized_params
      |> auto_slot_changeset()
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign(:auto_slot_form, to_form(changeset, as: :auto_slot))
     |> assign(:auto_excluded_date_inputs, excluded_date_inputs)}
  end

  def handle_event("create_auto_slots", %{"auto_slot" => params}, socket) do
    excluded_date_inputs = excluded_date_inputs_from_params(params)
    changeset = params |> normalize_auto_slot_params() |> auto_slot_changeset()

    if changeset.valid? do
      {created_count, skipped_count, focus_date} =
        create_auto_slots_for_resource(
          socket.assigns.current_user,
          socket.assigns.resource,
          socket.assigns.resource_slots,
          changeset
        )

      selected_date = focus_date || socket.assigns.selected_calendar_date
      visible_month = if selected_date, do: month_start(selected_date), else: socket.assigns.visible_calendar_month

      {:noreply,
       socket
       |> put_flash(:info, auto_slot_result_message(created_count, skipped_count))
       |> assign(:show_auto_slot_modal, false)
       |> assign(:auto_slot_form, to_form(default_auto_slot_changeset(), as: :auto_slot))
       |> assign(:auto_excluded_date_inputs, [""])
       |> assign_resource_slot_state(socket.assigns.resource,
         selected_date: selected_date,
         visible_month: visible_month
       )}
    else
      {:noreply,
       socket
       |> assign(:auto_slot_form, to_form(Map.put(changeset, :action, :insert), as: :auto_slot))
       |> assign(:auto_excluded_date_inputs, excluded_date_inputs)}
    end
  end

  def handle_event("add_auto_excluded_date", _params, socket) do
    {:noreply, assign(socket, :auto_excluded_date_inputs, append_excluded_date_row(socket.assigns.auto_excluded_date_inputs))}
  end

  def handle_event("remove_auto_excluded_date", %{"index" => index}, socket) do
    {:noreply, assign(socket, :auto_excluded_date_inputs, remove_excluded_date_row(socket.assigns.auto_excluded_date_inputs, index))}
  end

  def handle_event("select_calendar_date", %{"date" => selected_date}, socket) do
    case Date.from_iso8601(selected_date) do
      {:ok, date} ->
        {:noreply,
         assign_resource_slot_state(socket, socket.assigns.resource,
           selected_date: date,
           visible_month: month_start(date)
         )}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("prev_calendar_month", _params, socket) do
    target_month =
      socket.assigns.visible_calendar_month
      |> default_visible_month()
      |> shift_month(-1)

    {:noreply,
     assign_resource_slot_state(socket, socket.assigns.resource,
       selected_date: select_date_for_month(socket.assigns.selected_calendar_date, target_month),
       visible_month: target_month
     )}
  end

  def handle_event("next_calendar_month", _params, socket) do
    target_month =
      socket.assigns.visible_calendar_month
      |> default_visible_month()
      |> shift_month(1)

    {:noreply,
     assign_resource_slot_state(socket, socket.assigns.resource,
       selected_date: select_date_for_month(socket.assigns.selected_calendar_date, target_month),
       visible_month: target_month
     )}
  end

  def handle_event("confirm_delete", _params, socket) do
    case CompanyConsole.delete_company_resource(socket.assigns.resource) do
      {:ok, _resource} ->
        {:noreply,
         socket
         |> put_flash(:info, "Company resource deleted.")
         |> push_patch(to: ~p"/company/console/resources")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Company resource could not be deleted.")}
    end
  end

  defp load_resource(socket, nil, _action) do
    {:noreply,
     socket
     |> put_flash(:error, "That company resource was not found.")
     |> push_patch(to: ~p"/company/console/resources")}
  end

  defp load_resource(socket, id, action) do
    case CompanyConsole.get_company_resource(socket.assigns.current_user, id) do
      nil ->
        {:noreply,
         socket
         |> put_flash(:error, "That company resource was not found.")
         |> push_patch(to: ~p"/company/console/resources")}

      resource ->
        socket =
          socket
          |> assign(:resource, resource)
          |> assign(:page_title, company_resource_page_title(action, resource))
          |> assign(:form, form_for_action(socket.assigns.current_user, action, resource))

        socket =
          if action == :show do
            auto_changeset = default_auto_slot_changeset()

            socket
            |> assign(:auto_slot_form, to_form(auto_changeset, as: :auto_slot))
            |> assign(:auto_excluded_date_inputs, excluded_date_inputs_from_changeset(auto_changeset))
            |> assign(:show_manual_slot_modal, false)
            |> assign(:show_auto_slot_modal, false)
            |> assign_resource_slot_state(resource)
            |> reset_manual_slot_state()
          else
            clear_slot_state(socket)
          end

        {:noreply, socket}
    end
  end

  defp assign_resource_slot_state(socket, %CompanyResource{} = resource, opts \\ []) do
    slots = resource_slots(socket.assigns.current_user, resource.id)

    selected_date = resolve_selected_date(slots, Keyword.get(opts, :selected_date, socket.assigns.selected_calendar_date))

    visible_month = resolve_visible_month(selected_date, Keyword.get(opts, :visible_month, socket.assigns.visible_calendar_month))

    socket
    |> assign(:resource_slots, slots)
    |> assign(:selected_calendar_date, selected_date)
    |> assign(:visible_calendar_month, visible_month)
    |> assign(:calendar_month, build_calendar_month(slots, visible_month, selected_date))
    |> assign(:selected_calendar_slots, slots_for_date(slots, selected_date))
  end

  defp reset_manual_slot_state(socket) do
    selected_date = socket.assigns.selected_calendar_date || Date.utc_today()

    socket
    |> assign(:manual_slot_date, selected_date)
    |> assign(:manual_selected_ranges, [])
    |> assign(:manual_slot_max_bookings, "")
    |> assign(:manual_slot_error, nil)
  end

  defp clear_slot_state(socket) do
    socket
    |> assign(:resource_slots, [])
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
    |> assign(:bookings_modal_resource_id, nil)
    |> assign(:bookings_modal_resource_name, nil)
    |> assign(:bookings_modal_bookings, [])
    |> assign(:editing_booking_id, nil)
    |> assign(:booking_edit_form, nil)
  end

  defp fetch_resource_booking(socket, booking_id) do
    resource_id = socket.assigns.bookings_modal_resource_id

    case CompanyConsole.get_company_booking(socket.assigns.current_user, booking_id) do
      %CompanyBooking{resource_id: ^resource_id} = booking -> {:ok, booking}
      _ -> {:error, :not_found}
    end
  end

  defp refresh_resource_bookings_modal(socket) do
    case socket.assigns.bookings_modal_resource_id do
      resource_id when is_binary(resource_id) ->
        assign(
          socket,
          :bookings_modal_bookings,
          CompanyConsole.list_company_bookings_for_resource(socket.assigns.current_user, resource_id)
        )

      _ ->
        socket
    end
  end

  defp maybe_refresh_resource_slot_calendar(socket) do
    if socket.assigns.live_action == :show and
         match?(%CompanyResource{}, socket.assigns.resource) and
         socket.assigns.resource.id == socket.assigns.bookings_modal_resource_id do
      assign_resource_slot_state(socket, socket.assigns.resource)
    else
      socket
    end
  end

  defp resource_slots(user, resource_id) do
    slots =
      user
      |> CompanyConsole.list_company_slots()
      |> Enum.filter(&(&1.resource_id == resource_id))
      |> Enum.sort_by(fn slot -> slot.start_time && DateTime.to_unix(slot.start_time) end, :asc)

    booking_counts = CompanyConsole.confirmed_company_booking_counts_by_slot_ids(user, Enum.map(slots, & &1.id))

    Enum.map(slots, fn slot ->
      Map.put(slot, :booking_count, Map.get(booking_counts, slot.id, 0))
    end)
  end

  defp manual_slot_attrs(%CompanyResource{} = resource, attrs) when is_map(attrs) do
    attrs = stringify_keys(attrs)
    default_start = Map.get(attrs, "start_time") || default_manual_slot_start()

    attrs
    |> Map.put_new("start_time", default_start)
    |> Map.put_new("end_time", default_manual_slot_end(default_start))
    |> Map.put("status", "available")
    |> Map.put("source_type", "manual")
    |> Map.put("service_id", nil)
    |> Map.put("resource_id", resource.id)
  end

  defp default_manual_slot_start do
    DateTime.utc_now()
    |> DateTime.truncate(:second)
    |> DateTime.add(24 * 60 * 60, :second)
  end

  defp default_manual_slot_end(start_time) do
    DateTime.add(start_time, @default_manual_slot_minutes * 60, :second)
  end

  defp default_auto_slot_changeset do
    auto_slot_changeset(%{
      "auto_slots_enabled" => true,
      "default_max_bookings" => nil,
      "schedule_start_date" => Date.add(Date.utc_today(), 1),
      "schedule_end_date" => Date.add(Date.utc_today(), @default_auto_slot_days),
      "work_start_time" => ~T[09:00:00],
      "work_end_time" => ~T[18:00:00],
      "slot_minutes" => 60,
      "break_minutes" => 10,
      "lunch_start_time" => nil,
      "lunch_end_time" => nil,
      "available_weekdays" => "mon,tue,wed,thu,fri",
      "excluded_dates" => ""
    })
  end

  defp auto_slot_changeset(attrs) when is_map(attrs) do
    types = %{
      auto_slots_enabled: :boolean,
      default_max_bookings: :integer,
      schedule_start_date: :date,
      schedule_end_date: :date,
      work_start_time: :time,
      work_end_time: :time,
      slot_minutes: :integer,
      break_minutes: :integer,
      lunch_start_time: :time,
      lunch_end_time: :time,
      available_weekdays: :string,
      excluded_dates: :string
    }

    {%{}, types}
    |> Ecto.Changeset.cast(attrs, Map.keys(types))
    |> Ecto.Changeset.validate_required([:schedule_start_date, :schedule_end_date, :work_start_time, :work_end_time, :slot_minutes, :break_minutes, :available_weekdays])
    |> Ecto.Changeset.validate_number(:slot_minutes, greater_than: 0, less_than_or_equal_to: 720)
    |> Ecto.Changeset.validate_number(:break_minutes, greater_than_or_equal_to: 0, less_than_or_equal_to: 180)
    |> Ecto.Changeset.validate_number(:default_max_bookings, greater_than: 0)
    |> Ecto.Changeset.validate_change(:available_weekdays, fn :available_weekdays, value ->
      if parse_weekdays(value) == [] do
        [available_weekdays: "select at least one weekday"]
      else
        []
      end
    end)
    |> validate_auto_slots_enabled()
    |> validate_auto_date_range()
    |> validate_auto_time_range()
    |> validate_lunch_time_range()
    |> validate_excluded_dates()
  end

  defp validate_auto_slots_enabled(changeset) do
    if Ecto.Changeset.get_field(changeset, :auto_slots_enabled) do
      changeset
    else
      Ecto.Changeset.add_error(changeset, :auto_slots_enabled, "must be enabled to generate slots")
    end
  end

  defp validate_auto_date_range(changeset) do
    start_date = Ecto.Changeset.get_field(changeset, :schedule_start_date)
    end_date = Ecto.Changeset.get_field(changeset, :schedule_end_date)

    cond do
      is_nil(start_date) or is_nil(end_date) ->
        changeset

      Date.compare(end_date, start_date) in [:eq, :gt] ->
        changeset

      true ->
        Ecto.Changeset.add_error(changeset, :schedule_end_date, "must be on or after start date")
    end
  end

  defp validate_auto_time_range(changeset) do
    work_start_time = Ecto.Changeset.get_field(changeset, :work_start_time)
    work_end_time = Ecto.Changeset.get_field(changeset, :work_end_time)

    cond do
      is_nil(work_start_time) or is_nil(work_end_time) ->
        changeset

      Time.after?(work_end_time, work_start_time) ->
        changeset

      true ->
        Ecto.Changeset.add_error(changeset, :work_end_time, "must be after work start time")
    end
  end

  defp validate_lunch_time_range(changeset) do
    lunch_start_time = Ecto.Changeset.get_field(changeset, :lunch_start_time)
    lunch_end_time = Ecto.Changeset.get_field(changeset, :lunch_end_time)
    work_start_time = Ecto.Changeset.get_field(changeset, :work_start_time)
    work_end_time = Ecto.Changeset.get_field(changeset, :work_end_time)

    cond do
      is_nil(lunch_start_time) and is_nil(lunch_end_time) ->
        changeset

      is_nil(lunch_start_time) or is_nil(lunch_end_time) ->
        changeset
        |> Ecto.Changeset.add_error(:lunch_start_time, "set both lunch start and lunch end")
        |> Ecto.Changeset.add_error(:lunch_end_time, "set both lunch start and lunch end")

      Time.compare(lunch_end_time, lunch_start_time) != :gt ->
        Ecto.Changeset.add_error(changeset, :lunch_end_time, "must be after lunch start")

      is_struct(work_start_time, Time) and Time.before?(lunch_start_time, work_start_time) ->
        Ecto.Changeset.add_error(changeset, :lunch_start_time, "must be within work hours")

      is_struct(work_end_time, Time) and Time.after?(lunch_end_time, work_end_time) ->
        Ecto.Changeset.add_error(changeset, :lunch_end_time, "must be within work hours")

      true ->
        changeset
    end
  end

  defp validate_excluded_dates(changeset) do
    value = Ecto.Changeset.get_field(changeset, :excluded_dates)

    case parse_excluded_dates(value) do
      {:ok, _dates} -> changeset
      {:error, _reason} -> Ecto.Changeset.add_error(changeset, :excluded_dates, "contains invalid date values")
    end
  end

  defp create_auto_slots_for_resource(user, %CompanyResource{} = resource, existing_slots, changeset) do
    config = %{
      auto_slots_enabled: Ecto.Changeset.get_field(changeset, :auto_slots_enabled),
      start_date: Ecto.Changeset.get_field(changeset, :schedule_start_date),
      end_date: Ecto.Changeset.get_field(changeset, :schedule_end_date),
      work_start_time: Ecto.Changeset.get_field(changeset, :work_start_time),
      work_end_time: Ecto.Changeset.get_field(changeset, :work_end_time),
      slot_minutes: Ecto.Changeset.get_field(changeset, :slot_minutes),
      break_minutes: Ecto.Changeset.get_field(changeset, :break_minutes),
      lunch_start_time: Ecto.Changeset.get_field(changeset, :lunch_start_time),
      lunch_end_time: Ecto.Changeset.get_field(changeset, :lunch_end_time),
      weekdays: parse_weekdays(Ecto.Changeset.get_field(changeset, :available_weekdays)),
      excluded_dates: parse_excluded_dates!(Ecto.Changeset.get_field(changeset, :excluded_dates)),
      max_bookings: Ecto.Changeset.get_field(changeset, :default_max_bookings)
    }

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

          case CompanyConsole.create_company_slot(user, attrs) do
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

  defp parse_weekdays(value) when is_binary(value) do
    value
    |> String.split(",", trim: true)
    |> Enum.map(&(&1 |> String.trim() |> String.downcase()))
    |> Enum.reduce([], fn weekday, acc ->
      case Map.get(@weekday_to_number, weekday) do
        nil -> acc
        day_number -> [day_number | acc]
      end
    end)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp parse_weekdays(_value), do: []

  defp parse_excluded_dates!(value) do
    case parse_excluded_dates(value) do
      {:ok, dates} -> dates
      {:error, _reason} -> MapSet.new()
    end
  end

  defp parse_excluded_dates(nil), do: {:ok, MapSet.new()}
  defp parse_excluded_dates(""), do: {:ok, MapSet.new()}

  defp parse_excluded_dates(value) when is_binary(value) do
    value
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
    |> parse_excluded_dates()
  end

  defp parse_excluded_dates(values) when is_list(values) do
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

  defp normalize_auto_slot_params(params) when is_map(params) do
    params
    |> Map.update("available_weekdays", "", &normalize_weekday_param/1)
    |> Map.update("excluded_dates", "", &normalize_excluded_date_param/1)
  end

  defp normalize_weekday_param(value) do
    value
    |> normalize_weekday_values()
    |> Enum.join(",")
  end

  defp normalize_weekday_values(nil), do: []
  defp normalize_weekday_values(""), do: []

  defp normalize_weekday_values(value) when is_binary(value) do
    value
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
    |> normalize_weekday_values()
  end

  defp normalize_weekday_values(values) when is_list(values) do
    allowed = MapSet.new(@weekday_values)

    values
    |> Enum.reduce(MapSet.new(), fn
      value, acc when is_binary(value) ->
        trimmed = String.trim(value)

        if trimmed == "" or not MapSet.member?(allowed, trimmed) do
          acc
        else
          MapSet.put(acc, trimmed)
        end

      _, acc ->
        acc
    end)
    |> then(fn selected ->
      Enum.filter(@weekday_values, &MapSet.member?(selected, &1))
    end)
  end

  defp normalize_excluded_date_param(value) do
    value
    |> normalize_excluded_date_values()
    |> Enum.join(",")
  end

  defp normalize_excluded_date_values(nil), do: []
  defp normalize_excluded_date_values(""), do: []

  defp normalize_excluded_date_values(value) when is_binary(value) do
    value
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
    |> normalize_excluded_date_values()
  end

  defp normalize_excluded_date_values(values) when is_list(values) do
    values
    |> Enum.reduce(MapSet.new(), fn
      value, acc when is_binary(value) ->
        trimmed = String.trim(value)

        case Date.from_iso8601(trimmed) do
          {:ok, _date} -> MapSet.put(acc, trimmed)
          _ -> acc
        end

      _, acc ->
        acc
    end)
    |> MapSet.to_list()
    |> Enum.sort()
  end

  defp excluded_date_inputs_from_changeset(changeset) do
    changeset
    |> Ecto.Changeset.get_field(:excluded_dates)
    |> normalize_excluded_date_values()
    |> ensure_excluded_date_input_row()
  end

  defp excluded_date_inputs_from_params(params) when is_map(params) do
    params
    |> Map.get("excluded_dates")
    |> normalize_excluded_date_values()
    |> ensure_excluded_date_input_row()
  end

  defp append_excluded_date_row(values) do
    rows =
      case values do
        list when is_list(list) and list != [] -> list
        _ -> [""]
      end

    rows ++ [""]
  end

  defp remove_excluded_date_row(values, index) do
    case Integer.parse(to_string(index)) do
      {index_value, ""} ->
        values
        |> List.delete_at(index_value)
        |> ensure_excluded_date_input_row()

      _ ->
        ensure_excluded_date_input_row(values)
    end
  end

  defp ensure_excluded_date_input_row(values) when is_list(values) do
    case Enum.reject(values, &(&1 == "")) do
      [] -> [""]
      sanitized -> sanitized
    end
  end

  defp auto_slot_result_message(created_count, skipped_count) do
    "자동 slot #{created_count}개 생성, #{skipped_count}개 건너뜀(중복/검증 실패)."
  end

  defp manual_slot_result_message(created_count, skipped_count) do
    "수동 slot #{created_count}개 생성, #{skipped_count}개 건너뜀(중복/검증 실패)."
  end

  defp parse_manual_slot_date(value, fallback_date) do
    case Date.from_iso8601(to_string(value || "")) do
      {:ok, date} -> date
      _ -> fallback_date
    end
  end

  defp parse_manual_slot_max_bookings(value) do
    value = normalize_manual_slot_max_bookings(value)

    if value == "" do
      {:ok, nil}
    else
      case Integer.parse(value) do
        {parsed, ""} when parsed > 0 -> {:ok, parsed}
        _ -> {:error, :invalid_max_bookings}
      end
    end
  end

  defp normalize_manual_slot_max_bookings(nil), do: ""
  defp normalize_manual_slot_max_bookings(value), do: String.trim(to_string(value))

  defp parse_manual_slot_index(value, min_value, max_value) do
    case Integer.parse(to_string(value || "")) do
      {parsed, ""} when parsed >= min_value and parsed <= max_value -> {:ok, parsed}
      _ -> {:error, :invalid_index}
    end
  end

  defp normalize_manual_slot_ranges(ranges) when is_list(ranges) do
    max_slots = manual_slot_index_limit()

    ranges
    |> Enum.filter(fn
      %{start_index: start_index, end_index: end_index}
      when is_integer(start_index) and is_integer(end_index) and start_index >= 0 and end_index <= max_slots and start_index < end_index ->
        true

      _ ->
        false
    end)
    |> Enum.sort_by(fn range -> {range.start_index, range.end_index} end)
    |> Enum.reduce([], fn range, acc ->
      case acc do
        [%{start_index: current_start, end_index: current_end} | tail] ->
          if range.start_index < current_end do
            [%{start_index: current_start, end_index: max(current_end, range.end_index)} | tail]
          else
            [range | acc]
          end

        [] ->
          [range]
      end
    end)
    |> Enum.reverse()
  end

  defp remove_manual_slot_range(ranges, index) do
    case Integer.parse(to_string(index)) do
      {index_value, ""} ->
        ranges
        |> List.delete_at(index_value)
        |> normalize_manual_slot_ranges()

      _ ->
        ranges
    end
  end

  defp manual_slot_index_limit, do: div(24 * 60, @manual_drag_step_minutes)

  defp manual_hour_stats(_slots, nil), do: %{}

  defp manual_hour_stats(slots, %Date{} = date) do
    slots
    |> Enum.filter(fn slot -> slot_date(slot) == date and match?(%DateTime{}, slot.start_time) end)
    |> Enum.reduce(%{}, fn slot, acc ->
      hour = slot.start_time.hour
      slot_count = 1
      booking_count = slot_booking_count(slot)

      Map.update(acc, hour, %{slot_count: slot_count, booking_count: booking_count}, fn current ->
        %{
          slot_count: current.slot_count + slot_count,
          booking_count: current.booking_count + booking_count
        }
      end)
    end)
  end

  defp hour_slot_count(stats, hour), do: stats |> Map.get(hour, %{slot_count: 0}) |> Map.get(:slot_count, 0)
  defp hour_booking_count(stats, hour), do: stats |> Map.get(hour, %{booking_count: 0}) |> Map.get(:booking_count, 0)

  defp manual_time_segments do
    for index <- 0..(manual_slot_index_limit() - 1) do
      total_minutes = index * @manual_drag_step_minutes
      hour = div(total_minutes, 60)
      minute = rem(total_minutes, 60)

      %{
        index: index,
        hour: hour,
        minute: minute,
        label: if(minute == 0, do: manual_index_label(index), else: "")
      }
    end
  end

  defp manual_segment_selected?(ranges, index) do
    Enum.any?(ranges, fn range -> index >= range.start_index and index < range.end_index end)
  end

  defp manual_segment_minute_label(minute), do: String.pad_leading(Integer.to_string(minute), 2, "0")

  defp manual_slot_range_label(%{start_index: start_index, end_index: end_index}) do
    "#{manual_index_label(start_index)} - #{manual_index_label(end_index)}"
  end

  defp manual_index_label(index) when is_integer(index) and index >= 0 do
    total_minutes = index * @manual_drag_step_minutes
    hour = div(total_minutes, 60)
    minute = rem(total_minutes, 60)
    "#{String.pad_leading(Integer.to_string(hour), 2, "0")}:#{String.pad_leading(Integer.to_string(minute), 2, "0")}"
  end

  defp manual_slot_datetime(day_start, index) do
    DateTime.add(day_start, index * @manual_drag_step_minutes * 60, :second)
  end

  defp date_input_value(nil), do: ""
  defp date_input_value(%Date{} = date), do: Date.to_iso8601(date)

  defp resolve_selected_date(_slots, %Date{} = preferred_date), do: preferred_date

  defp resolve_selected_date(slots, _preferred_date) do
    case Enum.find(slots, &match?(%DateTime{}, &1.start_time)) do
      %{start_time: %DateTime{} = start_time} -> DateTime.to_date(start_time)
      _ -> Date.utc_today()
    end
  end

  defp resolve_visible_month(%Date{} = selected_date, nil), do: month_start(selected_date)
  defp resolve_visible_month(_selected_date, %Date{} = preferred_visible_month), do: month_start(preferred_visible_month)

  defp default_visible_month(nil), do: month_start(Date.utc_today())
  defp default_visible_month(%Date{} = month), do: month_start(month)

  defp select_date_for_month(%Date{} = selected_date, %Date{} = month) do
    if selected_date.year == month.year and selected_date.month == month.month do
      selected_date
    else
      month
    end
  end

  defp select_date_for_month(_selected_date, %Date{} = month), do: month

  defp build_calendar_month(slots, visible_month, selected_date) do
    first_day = month_start(visible_month)
    last_day = month_end(visible_month)
    slots_by_date = Enum.group_by(slots, &slot_date/1)

    leading_cells = List.duplicate(empty_calendar_day(), max(Date.day_of_week(first_day) - 1, 0))

    day_cells =
      Enum.map(Date.range(first_day, last_day), fn date ->
        day_slots = Map.get(slots_by_date, date, [])

        slot_count = length(day_slots)
        booking_count = Enum.reduce(day_slots, 0, fn slot, acc -> slot_booking_count(slot) + acc end)

        %{
          date: date,
          iso_date: Date.to_iso8601(date),
          day_number: date.day,
          slot_count: slot_count,
          booking_count: booking_count,
          outside_month: false,
          is_today: date == Date.utc_today(),
          is_selected: date == selected_date
        }
      end)

    total_cells = leading_cells ++ day_cells
    trailing_count = rem(7 - rem(length(total_cells), 7), 7)
    trailing_cells = List.duplicate(empty_calendar_day(), trailing_count)

    %{
      label: Calendar.strftime(first_day, "%B %Y"),
      day_headers: @calendar_day_headers,
      weeks: Enum.chunk_every(total_cells ++ trailing_cells, 7)
    }
  end

  defp empty_calendar_month do
    %{
      label: "",
      day_headers: @calendar_day_headers,
      weeks: []
    }
  end

  defp empty_calendar_day do
    %{
      date: nil,
      iso_date: nil,
      day_number: nil,
      slot_count: 0,
      booking_count: 0,
      outside_month: true,
      is_today: false,
      is_selected: false
    }
  end

  defp slots_for_date(slots, %Date{} = selected_date) do
    slots
    |> Enum.filter(&(slot_date(&1) == selected_date))
    |> Enum.sort_by(fn slot -> DateTime.to_unix(slot.start_time) end, :asc)
  end

  defp slot_date(%{start_time: %DateTime{} = start_time}), do: DateTime.to_date(start_time)
  defp slot_date(_slot), do: Date.utc_today()

  defp slot_window_key(%DateTime{} = start_time, %DateTime{} = end_time) do
    "#{DateTime.to_unix(start_time)}:#{DateTime.to_unix(end_time)}"
  end

  defp slot_window_key(_, _), do: ""

  defp shift_month(%Date{} = month, offset) when is_integer(offset) do
    absolute_month = month.year * 12 + month.month - 1 + offset
    year = div(absolute_month, 12)
    month_number = rem(absolute_month, 12) + 1
    Date.new!(year, month_number, 1)
  end

  defp month_start(%Date{} = date), do: Date.new!(date.year, date.month, 1)
  defp month_end(%Date{} = date), do: Date.new!(date.year, date.month, Date.days_in_month(date))

  defp selected_date_label(nil), do: "No date selected"
  defp selected_date_label(%Date{} = date), do: Calendar.strftime(date, "%A, %B %d")

  defp slot_time_range(slot) do
    "#{format_slot_datetime(slot.start_time)} to #{format_slot_datetime(slot.end_time)}"
  end

  defp format_slot_datetime(nil), do: "Unknown"
  defp format_slot_datetime(%DateTime{} = datetime), do: Calendar.strftime(datetime, "%Y-%m-%d %H:%M UTC")

  defp booking_slot_window(%{slot: %{start_time: start_time, end_time: end_time}}) do
    "#{format_slot_datetime(start_time)} to #{format_slot_datetime(end_time)}"
  end

  defp booking_slot_window(_booking), do: "Slot details unavailable"

  defp booking_status_badge_class("confirmed"), do: "rounded-full bg-emerald-50 px-2 py-0.5 text-[11px] font-semibold uppercase tracking-[0.16em] text-emerald-700"
  defp booking_status_badge_class("cancelled"), do: "rounded-full bg-rose-50 px-2 py-0.5 text-[11px] font-semibold uppercase tracking-[0.16em] text-rose-700"
  defp booking_status_badge_class("noshow"), do: "rounded-full bg-amber-50 px-2 py-0.5 text-[11px] font-semibold uppercase tracking-[0.16em] text-amber-700"
  defp booking_status_badge_class(_status), do: "rounded-full bg-slate-100 px-2 py-0.5 text-[11px] font-semibold uppercase tracking-[0.16em] text-slate-500"

  defp slot_capacity_label(%{max_bookings: nil}), do: "Unlimited"
  defp slot_capacity_label(%{max_bookings: max_bookings}), do: "Max #{max_bookings} bookings"

  defp slot_booking_count_label(slot) do
    count = slot_booking_count(slot)
    if count == 1, do: "1 booking", else: "#{count} bookings"
  end

  defp slot_booking_count(%{booking_count: count}) when is_integer(count) and count > 0, do: count
  defp slot_booking_count(_slot), do: 0

  defp slot_status_label(:available), do: "Available"
  defp slot_status_label(:booked), do: "Booked"
  defp slot_status_label(:cancelled), do: "Cancelled"
  defp slot_status_label(value), do: value |> to_string() |> String.capitalize()

  defp slot_source_label(:generated), do: "Auto"
  defp slot_source_label(:manual), do: "Manual"
  defp slot_source_label(_value), do: "Manual"

  defp slot_status_badge_class(:available), do: "rounded-full bg-emerald-50 px-2 py-0.5 text-[11px] font-semibold text-emerald-700"
  defp slot_status_badge_class(:booked), do: "rounded-full bg-brand-50 px-2 py-0.5 text-[11px] font-semibold text-brand-700"
  defp slot_status_badge_class(:cancelled), do: "rounded-full bg-slate-100 px-2 py-0.5 text-[11px] font-semibold text-slate-500"
  defp slot_status_badge_class(_), do: "rounded-full bg-slate-100 px-2 py-0.5 text-[11px] font-semibold text-slate-500"

  defp slot_source_badge_class(:generated), do: "rounded-full bg-indigo-50 px-2 py-0.5 text-[11px] font-semibold text-indigo-700"
  defp slot_source_badge_class(_), do: "rounded-full bg-slate-100 px-2 py-0.5 text-[11px] font-semibold text-slate-600"

  defp calendar_nav_button_class do
    "inline-flex items-center rounded-full border border-slate-200 bg-white px-3 py-1.5 text-xs font-semibold uppercase tracking-[0.18em] text-slate-600 transition hover:border-slate-300 hover:bg-slate-100"
  end

  defp calendar_day_button_class(day) do
    [
      "flex h-full w-full flex-col rounded-2xl px-2.5 py-2 text-left transition",
      day.is_selected && "bg-slate-950 text-white",
      !day.is_selected && day.is_today && "bg-brand-25 hover:bg-brand-50",
      !day.is_selected && !day.is_today && "hover:bg-slate-50"
    ]
  end

  defp time_select_input(assigns) do
    field = assigns.field

    assigns =
      assigns
      |> assign(:id, field.id)
      |> assign(:name, field.name)
      |> assign(:value, normalize_time_value(field.value))
      |> assign(:errors, field_errors(field))

    ~H"""
    <div>
      <.label for={@id}>{@label}</.label>
      <select
        id={@id}
        name={@name}
        class={[
          "mt-2 block w-full rounded-md border bg-white shadow-sm focus:ring-0 sm:text-sm",
          @errors == [] && "border-gray-300 focus:border-zinc-400",
          @errors != [] && "border-rose-400 focus:border-rose-400"
        ]}
      >
        <option :if={@prompt} value="" selected={@value in [nil, ""]}>{@prompt}</option>
        {Phoenix.HTML.Form.options_for_select(@options, @value)}
      </select>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  defp weekday_checkboxes(assigns) do
    field = assigns.field

    assigns =
      assigns
      |> assign(:id, field.id)
      |> assign(:name, field.name)
      |> assign(:errors, field_errors(field))
      |> assign(:selected_values, normalize_weekday_values(field.value))
      |> assign(:options, @weekday_options)

    ~H"""
    <div class="md:col-span-2">
      <.label for={"#{@id}-mon"}>Available weekdays</.label>
      <input type="hidden" name={@name <> "[]"} value="" />
      <div class="mt-3 flex flex-wrap gap-2">
        <label
          :for={{label, value} <- @options}
          for={"#{@id}-#{value}"}
          class={[
            "inline-flex cursor-pointer items-center rounded-full border px-3 py-2 text-sm font-semibold transition",
            value in @selected_values && "border-brand-600 bg-brand-50 text-brand-700",
            value not in @selected_values && "border-slate-300 bg-white text-slate-600 hover:border-slate-400 hover:text-slate-900"
          ]}
        >
          <input
            id={"#{@id}-#{value}"}
            type="checkbox"
            name={@name <> "[]"}
            value={value}
            checked={value in @selected_values}
            class="sr-only"
          />
          <span><%= label %></span>
        </label>
      </div>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  defp excluded_date_inputs(assigns) do
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

  defp field_errors(field) do
    if Phoenix.Component.used_input?(field) do
      Enum.map(field.errors, &translate_error/1)
    else
      []
    end
  end

  defp normalize_time_value(nil), do: nil
  defp normalize_time_value(""), do: ""
  defp normalize_time_value(%Time{} = value), do: Calendar.strftime(value, "%H:%M")
  defp normalize_time_value(value) when is_binary(value), do: value

  defp work_time_options, do: @work_time_options
  defp slot_minutes_options, do: @slot_minutes_options
  defp break_minutes_options, do: @break_minutes_options
  defp booking_status_options, do: @booking_status_options

  defp company_timezone_label(%{timezone: timezone}) when is_binary(timezone) and timezone != "", do: timezone
  defp company_timezone_label(_company), do: "Asia/Seoul"

  defp resource_changeset_for_action(%{assigns: %{live_action: :new, current_user: user}}, params) do
    CompanyConsole.change_company_resource(user, %CompanyResource{}, params)
  end

  defp resource_changeset_for_action(%{assigns: %{current_user: user, resource: resource}}, params) do
    CompanyConsole.change_company_resource(user, resource, params)
  end

  defp default_resource_changeset(user) do
    CompanyConsole.change_company_resource(user, %CompanyResource{}, %{
      "name" => "",
      "type" => "",
      "location" => "",
      "description" => "",
      "price" => "0.00",
      "currency" => "KRW"
    })
  end

  defp form_for_action(_user, :show, _resource), do: nil
  defp form_for_action(_user, :delete, _resource), do: nil

  defp form_for_action(user, :edit, resource) do
    user
    |> CompanyConsole.change_company_resource(resource)
    |> to_form(as: :resource)
  end

  defp resource_stats(resources) do
    %{
      total: length(resources),
      located: Enum.count(resources, &present?(&1.location)),
      priced: Enum.count(resources, &(not is_nil(&1.price)))
    }
  end

  defp company_resource_page_title(:show, resource), do: resource.name
  defp company_resource_page_title(:edit, resource), do: "Edit #{resource.name}"
  defp company_resource_page_title(:delete, resource), do: "Delete #{resource.name}"

  defp resource_page_label(:index), do: "Read"
  defp resource_page_label(:new), do: "Create"
  defp resource_page_label(:show), do: "Read"
  defp resource_page_label(:edit), do: "Update"
  defp resource_page_label(:delete), do: "Delete"

  defp cancel_resource_path(nil), do: ~p"/company/console/resources"
  defp cancel_resource_path(resource), do: ~p"/company/console/resources/#{resource.id}"

  defp action_link_class do
    "inline-flex items-center rounded-full px-3 py-2 text-sm font-medium text-slate-500 transition hover:bg-slate-100 hover:text-slate-900"
  end

  defp danger_action_link_class do
    "inline-flex items-center rounded-full px-3 py-2 text-sm font-medium text-danger-700 transition hover:bg-danger-50"
  end

  defp money(nil, currency), do: "0 #{currency || "KRW"}"
  defp money(price, currency), do: "#{price} #{currency}"
  defp present?(value), do: value not in [nil, ""]

  defp stringify_keys(attrs) when is_map(attrs) do
    Map.new(attrs, fn {key, value} -> {to_string(key), value} end)
  end
end
