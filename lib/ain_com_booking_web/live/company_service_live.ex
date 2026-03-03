defmodule AinComBookingWeb.CompanyServiceLive do
  @moduledoc false
  use AinComBookingWeb, :live_view

  import AinComBookingWeb.CompanyConsoleComponents

  alias AinComBooking.Catalog.CompanyService
  alias AinComBooking.CompanyConsole

  def render(assigns) do
    ~H"""
    <.shell
      current_user={@current_user}
      company={@company}
      active_section={:services}
      page_title={@page_title}
      page_label={service_page_label(@live_action)}
      page_subtitle="Company services are the main top-level offerings. Create booking pages from each service so customers get a dedicated URL."
    >
      <div class="space-y-5">
        <div :if={@live_action == :index} class="flex justify-end">
          <.link
            patch={~p"/company/console/services/new"}
            class="inline-flex items-center gap-2 rounded-full bg-brand-600 px-4 py-2 text-sm font-semibold text-white transition hover:bg-brand-500"
          >
            <.icon name="hero-plus" class="h-4 w-4" />
            <span>New Service</span>
          </.link>
        </div>

        <section :if={@live_action == :index} class="space-y-4">
          <div :if={@services == []} class="rounded-3xl border border-dashed border-slate-300 bg-slate-50 px-6 py-10 text-center text-sm text-slate-500">
            No company services yet. Create the first one to start publishing customer-facing booking pages.
          </div>

          <article
            :for={service <- @services}
            id={"company-service-#{service.id}"}
            class="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm"
          >
            <div class="flex flex-wrap items-start justify-between gap-4">
              <div class="min-w-0 flex-1">
                <div class="flex flex-wrap items-center gap-2">
                  <h2 class="text-lg font-semibold tracking-tight text-slate-950"><%= service.name %></h2>
                  <span class={status_badge_class(service.is_active)}>
                    <%= if service.is_active, do: "Active", else: "Paused" %>
                  </span>
                  <span class={visibility_badge_class(service.is_public)}>
                    <%= if service.is_public, do: "Public", else: "Private" %>
                  </span>
                </div>
                <p :if={present?(service.description_text)} class="mt-2 text-sm leading-6 text-slate-600"><%= service.description_text %></p>
                <div class="mt-3 flex flex-wrap items-center gap-4 text-xs font-medium text-slate-400">
                  <span class="inline-flex items-center gap-1">
                    <.icon name="hero-clock" class="h-4 w-4" />
                    <%= service.duration %> min
                  </span>
                  <span class="inline-flex items-center gap-1">
                    <.icon name="hero-banknotes" class="h-4 w-4" />
                    <%= money(service.price, service.currency) %>
                  </span>
                </div>
              </div>

              <div class="flex flex-wrap items-center gap-2">
                <.link patch={~p"/company/console/services/#{service.id}"} class={action_link_class()}>View</.link>
                <.link patch={~p"/company/console/services/#{service.id}/edit"} class={action_link_class()}>Edit</.link>
                <.link patch={~p"/company/console/services/#{service.id}/delete"} class={danger_action_link_class()}>Delete</.link>
              </div>
            </div>
          </article>
        </section>

        <section :if={@live_action == :new or @live_action == :edit} class="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
          <.simple_form for={@form} as={:service} id="company-service-form" phx-change="validate" phx-submit="save">
            <div class="grid gap-4 md:grid-cols-2">
              <.input field={@form[:name]} type="text" label="Name" />
              <.input field={@form[:currency]} type="text" label="Currency" />
              <.input field={@form[:duration]} type="number" label="Duration (minutes)" min="1" />
              <.input field={@form[:price]} type="number" label="Price" step="0.01" min="0" />
            </div>

            <.input field={@form[:description_text]} type="textarea" rows="4" label="Description" />

            <div class="grid gap-3 md:grid-cols-2">
              <.input field={@form[:is_active]} type="checkbox" label="Active" />
              <.input field={@form[:is_public]} type="checkbox" label="Public" />
              <.input field={@form[:is_recurring]} type="checkbox" label="Recurring" />
              <.input field={@form[:hide_duration]} type="checkbox" label="Hide duration" />
            </div>

            <:actions>
              <.button type="submit" phx-disable-with="Saving..." class="rounded-full bg-brand-600 px-5 hover:bg-brand-500">
                <%= if @live_action == :new, do: "Create Service", else: "Save Changes" %>
              </.button>
              <.link patch={cancel_service_path(@service)} class="rounded-full px-4 py-2 text-sm font-medium text-slate-500 transition hover:bg-slate-100 hover:text-slate-900">
                Cancel
              </.link>
            </:actions>
          </.simple_form>
        </section>

        <section :if={@live_action == :show and @service} class="space-y-4">
          <article class="rounded-3xl border border-slate-200 bg-white p-6 shadow-sm">
            <div class="flex flex-wrap items-start justify-between gap-4">
              <div class="min-w-0 flex-1">
                <div class="flex flex-wrap items-center gap-2">
                  <h2 class="text-2xl font-semibold tracking-tight text-slate-950"><%= @service.name %></h2>
                  <span class={status_badge_class(@service.is_active)}>
                    <%= if @service.is_active, do: "Active", else: "Paused" %>
                  </span>
                  <span class={visibility_badge_class(@service.is_public)}>
                    <%= if @service.is_public, do: "Public", else: "Private" %>
                  </span>
                </div>
                <p :if={present?(@service.description_text)} class="mt-3 text-sm leading-7 text-slate-600"><%= @service.description_text %></p>
              </div>

              <div class="flex flex-wrap items-center gap-2">
                <.link patch={~p"/company/console/services/#{@service.id}/edit"} class={action_link_class()}>Edit</.link>
                <.link patch={~p"/company/console/services/#{@service.id}/delete"} class={danger_action_link_class()}>Delete</.link>
              </div>
            </div>

            <dl class="mt-6 grid gap-4 md:grid-cols-2">
              <div class="rounded-2xl bg-slate-50 px-4 py-4">
                <dt class="text-xs font-semibold uppercase tracking-[0.18em] text-slate-400">Duration</dt>
                <dd class="mt-2 text-base font-semibold text-slate-900"><%= @service.duration %> minutes</dd>
              </div>
              <div class="rounded-2xl bg-slate-50 px-4 py-4">
                <dt class="text-xs font-semibold uppercase tracking-[0.18em] text-slate-400">Price</dt>
                <dd class="mt-2 text-base font-semibold text-slate-900"><%= money(@service.price, @service.currency) %></dd>
              </div>
            </dl>
          </article>

          <section class="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
            <div class="flex flex-wrap items-center justify-between gap-3">
              <div>
                <h3 class="text-lg font-semibold tracking-tight text-slate-950">Booking Pages For This Service</h3>
                <p class="mt-1 text-sm text-slate-500">Each page gets its own published customer URL.</p>
              </div>
              <.link
                navigate={service_booking_page_path(@service.id, nil, :new)}
                class="inline-flex items-center gap-2 rounded-full bg-slate-950 px-4 py-2 text-sm font-semibold text-white transition hover:bg-slate-800"
              >
                <.icon name="hero-link" class="h-4 w-4" />
                <span>Create Booking Page</span>
              </.link>
            </div>

            <div :if={@booking_pages == []} class="mt-4 rounded-2xl border border-dashed border-slate-300 bg-slate-50 px-4 py-6 text-sm text-slate-500">
              No booking pages yet for this service.
            </div>

            <div :if={@booking_pages != []} class="mt-4 space-y-3">
              <div :for={page <- @booking_pages} class="rounded-2xl border border-slate-200 bg-slate-50 px-4 py-4">
                <div class="flex flex-wrap items-center justify-between gap-3">
                  <div>
                    <div class="text-sm font-semibold text-slate-950"><%= page.title %></div>
                    <div class="mt-1 text-xs text-slate-400"><%= CompanyConsole.public_url(page) %></div>
                  </div>
                  <div class="flex flex-wrap items-center gap-2">
                    <span class={page_status_class(page.is_published)}>
                      <%= if page.is_published, do: "Published", else: "Draft" %>
                    </span>
                    <.link navigate={service_booking_page_path(@service.id, page.id, :show)} class={action_link_class()}>Open</.link>
                  </div>
                </div>
              </div>
            </div>
          </section>
        </section>

        <section :if={@live_action == :delete and @service} class="rounded-3xl border border-danger-200 bg-danger-25 p-6 shadow-sm">
          <p class="text-xs font-semibold uppercase tracking-[0.18em] text-danger-700">Delete Service</p>
          <h2 class="mt-2 text-2xl font-semibold tracking-tight text-slate-950"><%= @service.name %></h2>
          <p class="mt-3 text-sm leading-6 text-slate-600">
            This also removes any slots and booking pages linked to this service.
          </p>

          <div class="mt-5 flex flex-wrap items-center gap-3">
            <button
              type="button"
              phx-click="confirm_delete"
              class="inline-flex items-center gap-2 rounded-full bg-danger-600 px-5 py-2 text-sm font-semibold text-white transition hover:bg-danger-500"
            >
              <.icon name="hero-trash" class="h-4 w-4" />
              <span>Delete Service</span>
            </button>
            <.link patch={~p"/company/console/services/#{@service.id}"} class="rounded-full px-4 py-2 text-sm font-medium text-slate-500 transition hover:bg-white hover:text-slate-900">
              Cancel
            </.link>
          </div>
        </section>
      </div>

      <:sidebar>
        <div class="space-y-4">
          <div class="rounded-3xl border border-slate-200 bg-white p-4 shadow-sm">
            <h2 class="text-lg font-semibold tracking-tight text-slate-950">Service Snapshot</h2>
            <dl class="mt-3 space-y-3">
              <div class="flex items-center justify-between">
                <dt class="text-sm text-slate-500">Total</dt>
                <dd class="text-sm font-semibold text-slate-900"><%= @stats.total %></dd>
              </div>
              <div class="flex items-center justify-between">
                <dt class="text-sm text-slate-500">Active</dt>
                <dd class="text-sm font-semibold text-slate-900"><%= @stats.active %></dd>
              </div>
              <div class="flex items-center justify-between">
                <dt class="text-sm text-slate-500">Public</dt>
                <dd class="text-sm font-semibold text-slate-900"><%= @stats.public %></dd>
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
     |> assign(:service, nil)
     |> assign(:form, nil)
     |> assign(:services, [])
     |> assign(:booking_pages, [])
     |> assign(:stats, %{total: 0, active: 0, public: 0})
     |> assign(:page_title, "Company Services")}
  end

  def handle_params(params, _uri, socket) do
    services = CompanyConsole.list_company_services(socket.assigns.current_user)

    socket =
      socket
      |> assign(:services, services)
      |> assign(:stats, service_stats(services))

    case socket.assigns.live_action do
      :index ->
        {:noreply,
         socket
         |> assign(:page_title, "Company Services")
         |> assign(:service, nil)
         |> assign(:booking_pages, [])
         |> assign(:form, nil)}

      :new ->
        {:noreply,
         socket
         |> assign(:page_title, "Create Company Service")
         |> assign(:service, nil)
         |> assign(:booking_pages, [])
         |> assign(:form, to_form(default_service_changeset(socket.assigns.current_user), as: :service))}

      action ->
        load_service(socket, params["id"], action)
    end
  end

  def handle_event("validate", %{"service" => params}, socket) do
    changeset =
      socket
      |> service_changeset_for_action(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset, as: :service))}
  end

  def handle_event("save", %{"service" => params}, socket) do
    case socket.assigns.live_action do
      :new ->
        case CompanyConsole.create_company_service(socket.assigns.current_user, params) do
          {:ok, service} ->
            {:noreply,
             socket
             |> put_flash(:info, "Company service created.")
             |> push_patch(to: ~p"/company/console/services/#{service.id}")}

          {:error, changeset} ->
            {:noreply, assign(socket, :form, to_form(Map.put(changeset, :action, :insert), as: :service))}
        end

      :edit ->
        case CompanyConsole.update_company_service(socket.assigns.service, params) do
          {:ok, service} ->
            {:noreply,
             socket
             |> put_flash(:info, "Company service updated.")
             |> push_patch(to: ~p"/company/console/services/#{service.id}")}

          {:error, changeset} ->
            {:noreply, assign(socket, :form, to_form(Map.put(changeset, :action, :update), as: :service))}
        end
    end
  end

  def handle_event("confirm_delete", _params, socket) do
    case CompanyConsole.delete_company_service(socket.assigns.service) do
      {:ok, _service} ->
        {:noreply,
         socket
         |> put_flash(:info, "Company service deleted.")
         |> push_patch(to: ~p"/company/console/services")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Company service could not be deleted.")}
    end
  end

  defp load_service(socket, nil, _action) do
    {:noreply,
     socket
     |> put_flash(:error, "That company service was not found.")
     |> push_patch(to: ~p"/company/console/services")}
  end

  defp load_service(socket, id, action) do
    case CompanyConsole.get_company_service(socket.assigns.current_user, id) do
      nil ->
        {:noreply,
         socket
         |> put_flash(:error, "That company service was not found.")
         |> push_patch(to: ~p"/company/console/services")}

      service ->
        booking_pages = CompanyConsole.list_booking_pages_for_service(socket.assigns.current_user, service.id)

        {:noreply,
         socket
         |> assign(:service, service)
         |> assign(:booking_pages, booking_pages)
         |> assign(:page_title, company_service_page_title(action, service))
         |> assign(:form, form_for_action(socket.assigns.current_user, action, service))}
    end
  end

  defp service_changeset_for_action(%{assigns: %{live_action: :new, current_user: user}}, params) do
    CompanyConsole.change_company_service(user, %CompanyService{}, params)
  end

  defp service_changeset_for_action(%{assigns: %{current_user: user, service: service}}, params) do
    CompanyConsole.change_company_service(user, service, params)
  end

  defp default_service_changeset(user) do
    CompanyConsole.change_company_service(user, %CompanyService{}, %{
      "name" => "",
      "description_text" => "",
      "duration" => 30,
      "hide_duration" => false,
      "is_active" => true,
      "is_public" => true,
      "is_recurring" => false,
      "price" => "0.00",
      "currency" => "KRW"
    })
  end

  defp form_for_action(_user, :show, _service), do: nil
  defp form_for_action(_user, :delete, _service), do: nil

  defp form_for_action(user, :edit, service) do
    user
    |> CompanyConsole.change_company_service(service)
    |> to_form(as: :service)
  end

  defp service_stats(services) do
    %{
      total: length(services),
      active: Enum.count(services, & &1.is_active),
      public: Enum.count(services, & &1.is_public)
    }
  end

  defp company_service_page_title(:show, service), do: service.name
  defp company_service_page_title(:edit, service), do: "Edit #{service.name}"
  defp company_service_page_title(:delete, service), do: "Delete #{service.name}"

  defp service_page_label(:index), do: "Read"
  defp service_page_label(:new), do: "Create"
  defp service_page_label(:show), do: "Read"
  defp service_page_label(:edit), do: "Update"
  defp service_page_label(:delete), do: "Delete"

  defp cancel_service_path(nil), do: ~p"/company/console/services"
  defp cancel_service_path(service), do: ~p"/company/console/services/#{service.id}"

  defp service_booking_page_path(service_id, nil, :new), do: "/company/console/services/#{service_id}/pages/new"
  defp service_booking_page_path(service_id, page_id, :show), do: "/company/console/services/#{service_id}/pages/#{page_id}"
  defp service_booking_page_path(service_id, page_id, :edit), do: "/company/console/services/#{service_id}/pages/#{page_id}/edit"
  defp service_booking_page_path(service_id, page_id, :delete), do: "/company/console/services/#{service_id}/pages/#{page_id}/delete"

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
  defp page_status_class(true), do: "rounded-full bg-emerald-50 px-2.5 py-1 text-[11px] font-semibold text-emerald-700"
  defp page_status_class(false), do: "rounded-full bg-slate-100 px-2.5 py-1 text-[11px] font-semibold text-slate-500"
  defp money(nil, currency), do: "0 #{currency || "KRW"}"
  defp money(price, currency), do: "#{price} #{currency}"
  defp present?(value), do: value not in [nil, ""]
end
