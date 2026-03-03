defmodule AinComBookingWeb.CompanyBookingPageLive do
  @moduledoc false
  use AinComBookingWeb, :live_view

  import AinComBookingWeb.CompanyConsoleComponents

  alias AinComBooking.CompanyConsole
  alias AinComBooking.CompanyConsole.BookingPage

  @theme_options [
    {"Brand", "brand"},
    {"Neutral", "neutral"},
    {"Warm", "warm"}
  ]

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
      active_section={:pages}
      page_title={@page_title}
      page_label={booking_page_label(@live_action)}
      page_subtitle={@page_subtitle}
    >
      <div class="space-y-5">
        <section :if={@live_action == :index} class="space-y-4">
          <div :if={@pages == []} class="rounded-3xl border border-dashed border-slate-300 bg-slate-50 px-6 py-10 text-center text-sm text-slate-500">
            No booking pages yet. Create one from a company service or resource detail page.
          </div>

          <article
            :for={page <- @pages}
            id={"company-booking-page-#{page.id}"}
            class="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm"
          >
            <div class="flex flex-wrap items-start justify-between gap-4">
              <div class="min-w-0 flex-1">
                <div class="flex flex-wrap items-center gap-2">
                  <h2 class="text-lg font-semibold tracking-tight text-slate-950"><%= page.title %></h2>
                  <span class={status_badge_class(page.is_published)}>
                    <%= if page.is_published, do: "Published", else: "Draft" %>
                  </span>
                </div>
                <p :if={present?(page.description)} class="mt-2 text-sm leading-6 text-slate-600"><%= page.description %></p>
                <div class="mt-3 flex flex-wrap items-center gap-4 text-xs font-medium text-slate-400">
                  <span class="inline-flex items-center gap-1">
                    <.icon name="hero-link" class="h-4 w-4" />
                    <%= CompanyConsole.public_url(page) %>
                  </span>
                  <span class="inline-flex items-center gap-1">
                    <.icon name="hero-tag" class="h-4 w-4" />
                    <%= page_target_name(page) %>
                  </span>
                </div>
              </div>

              <div class="flex flex-wrap items-center gap-2">
                <.link patch={page_path(page, :show)} class={action_link_class()}>View</.link>
                <.link patch={page_path(page, :edit)} class={action_link_class()}>Edit</.link>
                <.link patch={page_path(page, :delete)} class={danger_action_link_class()}>Delete</.link>
              </div>
            </div>
          </article>
        </section>

        <section :if={@live_action == :new or @live_action == :edit} class="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
          <div class="mb-5 rounded-2xl bg-slate-50 px-4 py-4">
            <div class="text-xs font-semibold uppercase tracking-[0.18em] text-slate-400">Parent Target</div>
            <div class="mt-2 text-base font-semibold text-slate-950"><%= @parent_label %></div>
          </div>

          <.simple_form for={@form} as={:booking_page} id="company-booking-page-form" phx-change="validate" phx-submit="save">
            <div class="grid gap-4 md:grid-cols-2">
              <.input field={@form[:title]} type="text" label="Page Title" />
              <.input field={@form[:slug]} type="text" label="Published URL slug" />
              <.input field={@form[:button_label]} type="text" label="CTA Label" />
              <.input field={@form[:theme]} type="select" label="Theme" options={@theme_options} />
              <.input field={@form[:is_published]} type="checkbox" label="Publish immediately" />
            </div>

            <.input field={@form[:description]} type="textarea" rows="5" label="Description" />

            <div class="mt-6 rounded-2xl border border-slate-200 bg-slate-50 px-4 py-4">
              <div class="text-xs font-semibold uppercase tracking-[0.18em] text-slate-400">Automatic Availability</div>
              <p class="mt-2 text-sm leading-6 text-slate-500">
                Configure recurring working-hour based slots here. Exact one-off slots can still be created from `Company Slots`. Automatic rules use company local time
                (<%= company_timezone_label(@company) %>).
              </p>
            </div>

            <div class="grid gap-4 md:grid-cols-2">
              <.input field={@form[:auto_slots_enabled]} type="checkbox" label="Enable auto-generated slots" />
              <.input field={@form[:default_max_bookings]} type="number" label="Default max bookings per auto slot" min="1" />
              <.calendar_input field={@form[:schedule_start_date]} label="Schedule start date" />
              <.calendar_input field={@form[:schedule_end_date]} label="Schedule end date" />
              <.time_select_input field={@form[:work_start_time]} label="Work start time" prompt="Select start time" options={work_time_options()} />
              <.time_select_input field={@form[:work_end_time]} label="Work end time" prompt="Select end time" options={work_time_options()} />
              <.input field={@form[:slot_minutes]} type="select" label="Slot minutes" options={slot_minutes_options()} />
              <.input field={@form[:break_minutes]} type="select" label="Break minutes" options={break_minutes_options()} />
              <.time_select_input
                field={@form[:lunch_start_time]}
                label="Lunch start (optional)"
                prompt="Select lunch start"
                options={work_time_options()}
              />
              <.time_select_input
                field={@form[:lunch_end_time]}
                label="Lunch end (optional)"
                prompt="Select lunch end"
                options={work_time_options()}
              />
            </div>

            <.weekday_checkboxes field={@form[:available_weekdays]} />
            <.excluded_date_inputs dates={@excluded_date_inputs} />

            <:actions>
              <.button type="submit" phx-disable-with="Saving..." class="rounded-full bg-brand-600 px-5 hover:bg-brand-500">
                <%= if @live_action == :new, do: "Create Booking Page", else: "Save Changes" %>
              </.button>
              <.link patch={cancel_page_path(@live_action, @parent_type, @parent_id, @page)} class="rounded-full px-4 py-2 text-sm font-medium text-slate-500 transition hover:bg-slate-100 hover:text-slate-900">
                Cancel
              </.link>
            </:actions>
          </.simple_form>
        </section>

        <section :if={@live_action == :show and @page} class="space-y-4">
          <article class="rounded-3xl border border-slate-200 bg-white p-6 shadow-sm">
            <div class="flex flex-wrap items-start justify-between gap-4">
              <div class="min-w-0 flex-1">
                <div class="flex flex-wrap items-center gap-2">
                  <h2 class="text-2xl font-semibold tracking-tight text-slate-950"><%= @page.title %></h2>
                  <span class={status_badge_class(@page.is_published)}>
                    <%= if @page.is_published, do: "Published", else: "Draft" %>
                  </span>
                </div>
                <p :if={present?(@page.description)} class="mt-3 text-sm leading-7 text-slate-600"><%= @page.description %></p>
              </div>

              <div class="flex flex-wrap items-center gap-2">
                <.link patch={page_path(@page, :edit)} class={action_link_class()}>Edit</.link>
                <.link patch={page_path(@page, :delete)} class={danger_action_link_class()}>Delete</.link>
              </div>
            </div>

            <dl class="mt-6 grid gap-4 md:grid-cols-2">
              <div class="rounded-2xl bg-slate-50 px-4 py-4">
                <dt class="text-xs font-semibold uppercase tracking-[0.18em] text-slate-400">Published URL</dt>
                <dd class="mt-2 text-base font-semibold text-slate-900"><%= CompanyConsole.public_url(@page) %></dd>
              </div>
              <div class="rounded-2xl bg-slate-50 px-4 py-4">
                <dt class="text-xs font-semibold uppercase tracking-[0.18em] text-slate-400">Target</dt>
                <dd class="mt-2 text-base font-semibold text-slate-900"><%= page_target_name(@page) %></dd>
              </div>
            </dl>

            <div class="mt-6 rounded-3xl border border-slate-200 bg-slate-50 px-4 py-4">
              <div class="flex flex-wrap items-center justify-between gap-3">
                <div>
                  <h3 class="text-sm font-semibold text-slate-950">Availability Rules</h3>
                  <p class="mt-1 text-xs text-slate-400"><%= auto_schedule_summary(@page) %></p>
                </div>
                <.link navigate={~p"/company/console/slots"} class="inline-flex items-center rounded-full px-3 py-2 text-sm font-medium text-slate-500 transition hover:bg-white hover:text-slate-900">
                  Manage manual slots
                </.link>
              </div>
            </div>

            <div class="mt-5 flex flex-wrap items-center gap-3">
              <.link navigate={CompanyConsole.public_url(@page)} class="inline-flex items-center gap-2 rounded-full bg-slate-950 px-4 py-2 text-sm font-semibold text-white transition hover:bg-slate-800">
                <.icon name="hero-arrow-top-right-on-square" class="h-4 w-4" />
                <span>Open Public Page</span>
              </.link>
            </div>
          </article>

          <section class="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
            <div class="flex items-center justify-between gap-3">
              <h3 class="text-lg font-semibold tracking-tight text-slate-950">Next 7 Days Of Availability</h3>
              <div class="flex items-center gap-3">
                <span class="rounded-full bg-slate-100 px-3 py-1 text-[11px] font-semibold uppercase tracking-[0.16em] text-slate-500">
                  <%= CompanyConsole.company_timezone(@page) %>
                </span>
                <span class="text-sm font-semibold text-slate-500"><%= length(@upcoming_slots) %> open</span>
              </div>
            </div>

            <div :if={@upcoming_slots == []} class="mt-4 rounded-2xl border border-dashed border-slate-300 bg-slate-50 px-4 py-6 text-sm text-slate-500">
              No available slots for the next week. Add manual slots in `Company Slots` or enable automatic availability above.
            </div>

            <div :if={@upcoming_slots != []} class="mt-4 space-y-2">
              <div :for={slot <- @upcoming_slots} class="rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3">
                <div class="flex flex-wrap items-center justify-between gap-3">
                  <div class="text-sm font-semibold text-slate-950"><%= slot_name(slot) %></div>
                  <div class="text-xs text-slate-400">
                    <%= slot_time(@page, slot) %>
                    ·
                    <%= slot_capacity(slot) %>
                  </div>
                </div>
              </div>
            </div>
          </section>
        </section>

        <section :if={@live_action == :delete and @page} class="rounded-3xl border border-danger-200 bg-danger-25 p-6 shadow-sm">
          <p class="text-xs font-semibold uppercase tracking-[0.18em] text-danger-700">Delete Booking Page</p>
          <h2 class="mt-2 text-2xl font-semibold tracking-tight text-slate-950"><%= @page.title %></h2>
          <p class="mt-3 text-sm leading-6 text-slate-600">
            This unpublishes the customer URL entirely.
          </p>

          <div class="mt-5 flex flex-wrap items-center gap-3">
            <button
              type="button"
              phx-click="confirm_delete"
              class="inline-flex items-center gap-2 rounded-full bg-danger-600 px-5 py-2 text-sm font-semibold text-white transition hover:bg-danger-500"
            >
              <.icon name="hero-trash" class="h-4 w-4" />
              <span>Delete Booking Page</span>
            </button>
            <.link patch={page_path(@page, :show)} class="rounded-full px-4 py-2 text-sm font-medium text-slate-500 transition hover:bg-white hover:text-slate-900">
              Cancel
            </.link>
          </div>
        </section>
      </div>

      <:sidebar>
        <div class="space-y-4">
          <div class="rounded-3xl border border-slate-200 bg-white p-4 shadow-sm">
            <h2 class="text-lg font-semibold tracking-tight text-slate-950">Publishing</h2>
            <div class="mt-3 space-y-2 text-sm leading-6 text-slate-600">
              <p>Every page gets a dedicated slug and public URL.</p>
              <p>Create pages from service/resource detail screens so each customer path stays intentionally scoped.</p>
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
     |> assign(:theme_options, @theme_options)
     |> assign(:excluded_date_inputs, [""])
     |> assign(:page, nil)
     |> assign(:pages, [])
     |> assign(:form, nil)
     |> assign(:parent_type, nil)
     |> assign(:parent_id, nil)
     |> assign(:parent_label, nil)
     |> assign(:page_title, "Booking Pages")
     |> assign(:page_subtitle, "Published customer-facing URLs tied to company services or resources.")
     |> assign(:upcoming_slots, [])}
  end

  def handle_params(params, _uri, socket) do
    {parent_type, parent_id, parent_label} = resolve_parent(socket.assigns.current_user, params)
    pages = CompanyConsole.list_booking_pages(socket.assigns.current_user)

    socket =
      socket
      |> assign(:pages, pages)
      |> assign(:parent_type, parent_type)
      |> assign(:parent_id, parent_id)
      |> assign(:parent_label, parent_label)

    case socket.assigns.live_action do
      :index ->
        {:noreply,
         socket
         |> assign(:page_title, "Booking Pages")
         |> assign(:page_subtitle, "Published customer-facing URLs tied to company services or resources.")
         |> assign(:excluded_date_inputs, [""])
         |> assign(:page, nil)
         |> assign(:form, nil)
         |> assign(:upcoming_slots, [])}

      :new ->
        if parent_type do
          {:noreply,
           socket
           |> assign(:page_title, "Create Booking Page")
           |> assign(:page_subtitle, "This page will publish a dedicated customer booking URL under the selected parent.")
           |> assign(:page, nil)
           |> assign(:upcoming_slots, [])
           |> assign(:excluded_date_inputs, excluded_date_inputs_from_changeset(default_page_changeset(socket.assigns.current_user, parent_type, parent_id)))
           |> assign(:form, to_form(default_page_changeset(socket.assigns.current_user, parent_type, parent_id), as: :booking_page))}
        else
          {:noreply,
           socket
           |> put_flash(:error, "Choose a service or resource first.")
           |> push_patch(to: ~p"/company/console/pages")}
        end

      action ->
        load_page(socket, params["id"], action)
    end
  end

  def handle_event("validate", %{"booking_page" => params}, socket) do
    excluded_date_inputs = excluded_date_inputs_from_params(params)
    params = normalize_booking_page_params(params)

    changeset =
      socket.assigns.current_user
      |> CompanyConsole.change_booking_page(socket.assigns.parent_type, socket.assigns.parent_id, socket.assigns.page, params)
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign(:excluded_date_inputs, excluded_date_inputs)
     |> assign(:form, to_form(changeset, as: :booking_page))}
  end

  def handle_event("save", %{"booking_page" => params}, socket) do
    excluded_date_inputs = excluded_date_inputs_from_params(params)
    params = normalize_booking_page_params(params)

    result =
      case {socket.assigns.live_action, socket.assigns.parent_type} do
        {:new, :service} ->
          CompanyConsole.create_booking_page_for_service(socket.assigns.current_user, socket.assigns.parent_id, params)

        {:new, :resource} ->
          CompanyConsole.create_booking_page_for_resource(socket.assigns.current_user, socket.assigns.parent_id, params)

        {:edit, _parent_type} ->
          CompanyConsole.update_booking_page(socket.assigns.page, params)
      end

    case result do
      {:ok, page} ->
        {:noreply,
         socket
         |> put_flash(:info, "Booking page saved.")
         |> push_patch(to: page_path(page, :show))}

      {:error, :not_found} ->
        {:noreply,
         socket
         |> put_flash(:error, "That parent target was not found.")
         |> push_patch(to: ~p"/company/console/pages")}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(:excluded_date_inputs, excluded_date_inputs)
         |> assign(:form, to_form(Map.put(changeset, :action, :insert), as: :booking_page))}
    end
  end

  def handle_event("add_excluded_date", _params, socket) do
    {:noreply, assign(socket, :excluded_date_inputs, append_excluded_date_row(socket.assigns.excluded_date_inputs))}
  end

  def handle_event("remove_excluded_date", %{"index" => index}, socket) do
    {:noreply, assign(socket, :excluded_date_inputs, remove_excluded_date_row(socket.assigns.excluded_date_inputs, index))}
  end

  def handle_event("confirm_delete", _params, socket) do
    case CompanyConsole.delete_booking_page(socket.assigns.page) do
      {:ok, _page} ->
        {:noreply,
         socket
         |> put_flash(:info, "Booking page deleted.")
         |> push_patch(to: ~p"/company/console/pages")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Booking page could not be deleted.")}
    end
  end

  defp load_page(socket, nil, _action) do
    {:noreply,
     socket
     |> put_flash(:error, "That booking page was not found.")
     |> push_patch(to: ~p"/company/console/pages")}
  end

  defp load_page(socket, id, action) do
    case CompanyConsole.get_booking_page(socket.assigns.current_user, id) do
      nil ->
        {:noreply,
         socket
         |> put_flash(:error, "That booking page was not found.")
         |> push_patch(to: ~p"/company/console/pages")}

      page ->
        if page_matches_parent?(page, socket.assigns.parent_type, socket.assigns.parent_id) do
          {:noreply,
           socket
           |> assign(:page, page)
           |> assign(:page_title, booking_page_title(action, page))
           |> assign(:page_subtitle, "Published URL: #{CompanyConsole.public_url(page)}")
           |> assign(:upcoming_slots, if(action == :show, do: CompanyConsole.list_upcoming_slots_for_page(page), else: []))
           |> assign(:excluded_date_inputs, excluded_date_inputs_from_page(page))
           |> assign(:form, form_for_action(socket.assigns.current_user, action, socket.assigns.parent_type, socket.assigns.parent_id, page))}
        else
          {:noreply,
           socket
           |> put_flash(:error, "That booking page does not belong to the selected parent.")
           |> push_patch(to: ~p"/company/console/pages")}
        end
    end
  end

  defp resolve_parent(user, %{"service_id" => service_id}) when is_binary(service_id) do
    case CompanyConsole.get_company_service(user, service_id) do
      nil -> {nil, nil, nil}
      service -> {:service, service.id, "Service: #{service.name}"}
    end
  end

  defp resolve_parent(user, %{"resource_id" => resource_id}) when is_binary(resource_id) do
    case CompanyConsole.get_company_resource(user, resource_id) do
      nil -> {nil, nil, nil}
      resource -> {:resource, resource.id, "Resource: #{resource.name}"}
    end
  end

  defp resolve_parent(_user, _params), do: {nil, nil, nil}

  defp default_page_changeset(user, parent_type, parent_id) do
    CompanyConsole.change_booking_page(user, parent_type, parent_id, nil, %{
      "title" => "",
      "slug" => "",
      "description" => "",
      "button_label" => "Book now",
      "theme" => "brand",
      "is_published" => true,
      "auto_slots_enabled" => false,
      "slot_minutes" => 60,
      "break_minutes" => 10,
      "available_weekdays" => "mon,tue,wed,thu,fri",
      "excluded_dates" => ""
    })
  end

  defp calendar_input(assigns) do
    field = assigns.field

    assigns =
      assigns
      |> assign(:id, field.id)
      |> assign(:name, field.name)
      |> assign(:value, Phoenix.HTML.Form.normalize_value("date", field.value))
      |> assign(:errors, field_errors(field))

    ~H"""
    <div>
      <.label for={@id}>{@label}</.label>
      <div class="relative mt-2">
        <input
          type="date"
          id={@id}
          name={@name}
          value={@value}
          class={[
            "block w-full rounded-lg border bg-white pr-11 text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6",
            @errors == [] && "border-zinc-300 focus:border-zinc-400",
            @errors != [] && "border-rose-400 focus:border-rose-400"
          ]}
        />
        <.icon name="hero-calendar-days" class="pointer-events-none absolute right-3 top-1/2 h-5 w-5 -translate-y-1/2 text-slate-400" />
      </div>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
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
            "inline-flex items-center gap-2 rounded-full border px-3 py-2 text-sm font-medium transition",
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
            class="rounded border-slate-300 text-brand-600 focus:ring-0"
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
          <.label for="excluded-date-0">Excluded dates</.label>
          <p class="mt-1 text-xs text-slate-400">Pick specific holidays or blocked dates. Leave blank if not needed.</p>
        </div>
        <button
          type="button"
          phx-click="add_excluded_date"
          class="inline-flex items-center rounded-full px-3 py-2 text-sm font-medium text-slate-500 transition hover:bg-slate-100 hover:text-slate-900"
        >
          Add date
        </button>
      </div>

      <div class="mt-3 space-y-3">
        <div :for={{date, index} <- Enum.with_index(@dates)} class="flex items-center gap-3">
          <div class="relative min-w-0 flex-1">
            <input type="hidden" :if={index == 0} name="booking_page[excluded_dates][]" value="" />
            <input
              id={"excluded-date-#{index}"}
              type="date"
              name="booking_page[excluded_dates][]"
              value={date}
              class="block w-full rounded-lg border border-zinc-300 bg-white pr-11 text-zinc-900 focus:border-zinc-400 focus:ring-0 sm:text-sm sm:leading-6"
            />
            <.icon name="hero-calendar-days" class="pointer-events-none absolute right-3 top-1/2 h-5 w-5 -translate-y-1/2 text-slate-400" />
          </div>
          <button
            :if={@show_remove}
            type="button"
            phx-click="remove_excluded_date"
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

  defp normalize_booking_page_params(params) when is_map(params) do
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

  defp excluded_date_inputs_from_page(%BookingPage{} = page) do
    page
    |> Map.get(:excluded_dates)
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
    values
    |> normalize_excluded_date_values()
    |> Kernel.++([""])
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

  defp work_time_options, do: @work_time_options
  defp slot_minutes_options, do: @slot_minutes_options
  defp break_minutes_options, do: @break_minutes_options

  defp form_for_action(_user, :show, _parent_type, _parent_id, _page), do: nil
  defp form_for_action(_user, :delete, _parent_type, _parent_id, _page), do: nil

  defp form_for_action(user, :edit, parent_type, parent_id, page) do
    user
    |> CompanyConsole.change_booking_page(parent_type, parent_id, page)
    |> to_form(as: :booking_page)
  end

  defp page_matches_parent?(_page, nil, nil), do: true
  defp page_matches_parent?(%BookingPage{service_id: service_id}, :service, service_id), do: true
  defp page_matches_parent?(%BookingPage{resource_id: resource_id}, :resource, resource_id), do: true
  defp page_matches_parent?(_page, _parent_type, _parent_id), do: false

  defp booking_page_title(:show, page), do: page.title
  defp booking_page_title(:edit, page), do: "Edit #{page.title}"
  defp booking_page_title(:delete, page), do: "Delete #{page.title}"

  defp booking_page_label(:index), do: "Read"
  defp booking_page_label(:new), do: "Create"
  defp booking_page_label(:show), do: "Read"
  defp booking_page_label(:edit), do: "Update"
  defp booking_page_label(:delete), do: "Delete"

  defp page_path(%BookingPage{service_id: service_id, id: page_id}, :show) when is_binary(service_id), do: "/company/console/services/#{service_id}/pages/#{page_id}"

  defp page_path(%BookingPage{service_id: service_id, id: page_id}, :edit) when is_binary(service_id), do: "/company/console/services/#{service_id}/pages/#{page_id}/edit"

  defp page_path(%BookingPage{service_id: service_id, id: page_id}, :delete) when is_binary(service_id), do: "/company/console/services/#{service_id}/pages/#{page_id}/delete"

  defp page_path(%BookingPage{resource_id: resource_id, id: page_id}, :show) when is_binary(resource_id), do: "/company/console/resources/#{resource_id}/pages/#{page_id}"

  defp page_path(%BookingPage{resource_id: resource_id, id: page_id}, :edit) when is_binary(resource_id), do: "/company/console/resources/#{resource_id}/pages/#{page_id}/edit"

  defp page_path(%BookingPage{resource_id: resource_id, id: page_id}, :delete) when is_binary(resource_id), do: "/company/console/resources/#{resource_id}/pages/#{page_id}/delete"

  defp cancel_page_path(:new, :service, service_id, _page), do: ~p"/company/console/services/#{service_id}"
  defp cancel_page_path(:new, :resource, resource_id, _page), do: ~p"/company/console/resources/#{resource_id}"
  defp cancel_page_path(:edit, _parent_type, _parent_id, %BookingPage{} = page), do: page_path(page, :show)
  defp cancel_page_path(_action, _parent_type, _parent_id, _page), do: ~p"/company/console/pages"

  defp page_target_name(%BookingPage{service: %{name: name}}) when is_binary(name), do: "Service: #{name}"
  defp page_target_name(%BookingPage{resource: %{name: name}}) when is_binary(name), do: "Resource: #{name}"
  defp page_target_name(_page), do: "Unknown target"

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

  defp slot_capacity(%{remaining_capacity: nil}), do: "unlimited"
  defp slot_capacity(%{remaining_capacity: remaining_capacity}), do: "#{remaining_capacity} left"

  defp auto_schedule_summary(%BookingPage{auto_slots_enabled: false} = page) do
    "Automatic generation is off. This page currently uses only manual slots. Times stay in #{CompanyConsole.company_timezone(page)}."
  end

  defp auto_schedule_summary(%BookingPage{} = page) do
    Enum.join(
      [
        "Date range #{page.schedule_start_date || "?"} to #{page.schedule_end_date || "?"}",
        "work #{page.work_start_time || "?"} - #{page.work_end_time || "?"}",
        "#{page.slot_minutes || 60}m slots",
        "#{page.break_minutes || 0}m breaks",
        "days #{page.available_weekdays || "mon,tue,wed,thu,fri"}",
        "timezone #{CompanyConsole.company_timezone(page)}"
      ],
      " · "
    )
  end

  defp format_datetime(_page, nil), do: "Unknown"

  defp format_datetime(page, %DateTime{} = datetime) do
    local_datetime = CompanyConsole.page_local_datetime(page, datetime)
    "#{Calendar.strftime(local_datetime, "%Y-%m-%d %H:%M")} #{local_datetime.zone_abbr || local_datetime.time_zone}"
  end

  defp company_timezone_label(%{timezone: timezone}) when is_binary(timezone) and timezone != "", do: timezone
  defp company_timezone_label(_company), do: "Asia/Seoul"

  defp status_badge_class(true), do: "rounded-full bg-emerald-50 px-2.5 py-1 text-[11px] font-semibold text-emerald-700"
  defp status_badge_class(false), do: "rounded-full bg-slate-100 px-2.5 py-1 text-[11px] font-semibold text-slate-500"

  defp action_link_class do
    "inline-flex items-center rounded-full px-3 py-2 text-sm font-medium text-slate-500 transition hover:bg-slate-100 hover:text-slate-900"
  end

  defp danger_action_link_class do
    "inline-flex items-center rounded-full px-3 py-2 text-sm font-medium text-danger-700 transition hover:bg-danger-50"
  end

  defp present?(value), do: value not in [nil, ""]
end
