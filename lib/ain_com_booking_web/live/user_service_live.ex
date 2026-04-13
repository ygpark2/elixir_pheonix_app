defmodule AinComBookingWeb.UserServiceLive do
  @moduledoc false
  use AinComBookingWeb, :live_view

  alias AinComBooking.Catalog
  alias AinComBooking.Catalog.UserService

  def render(assigns) do
    ~H"""
    <style id="user-service-live-style">
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
              <div class="text-xs font-semibold uppercase tracking-[0.22em] text-brand-600">Services</div>
              <div class="mt-3 text-2xl font-semibold tracking-tight text-slate-950">Manage Services</div>
              <p class="mt-2 text-sm leading-6 text-slate-500">
                Create, review, update, and remove your bookable service offerings with one route per action.
              </p>
            </div>

            <nav class="space-y-2 rounded-3xl border border-slate-200 bg-white p-3 shadow-sm">
              <.link navigate={~p"/feed"} class={console_nav_class(false)}>
                <.icon name="hero-home-solid" class="h-5 w-5" />
                <span class="text-sm font-semibold">Home</span>
              </.link>
              <.link patch={~p"/services"} class={console_nav_class(true)}>
                <.icon name="hero-briefcase" class="h-5 w-5" />
                <span class="text-sm font-semibold">Services</span>
              </.link>
              <.link navigate={~p"/slots"} class={console_nav_class(false)}>
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
                <p class="mt-0.5 text-xs font-medium uppercase tracking-[0.18em] text-slate-400"><%= service_page_label(@live_action) %></p>
              </div>

              <.link
                :if={@live_action != :new}
                patch={~p"/services/new"}
                class="inline-flex items-center gap-2 rounded-full bg-brand-600 px-4 py-2 text-sm font-semibold text-white transition hover:bg-brand-500"
              >
                <.icon name="hero-plus" class="h-4 w-4" />
                <span>New Service</span>
              </.link>
            </div>
          </div>

          <section :if={@live_action == :index} class="space-y-4 px-4 py-4">
            <div :if={@services == []} class="rounded-3xl border border-dashed border-slate-300 bg-slate-50 px-6 py-10 text-center text-sm text-slate-500">
              No services yet. Create your first service to make it available in the booking feed.
            </div>

            <article
              :for={service <- @services}
              id={"service-#{service.id}"}
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
                  <.link patch={~p"/services/#{service.id}"} class={action_link_class()}>
                    View
                  </.link>
                  <.link patch={~p"/services/#{service.id}/edit"} class={action_link_class()}>
                    Edit
                  </.link>
                  <.link patch={~p"/services/#{service.id}/delete"} class={danger_action_link_class()}>
                    Delete
                  </.link>
                </div>
              </div>
            </article>
          </section>

          <section :if={@live_action == :new or @live_action == :edit} class="px-4 py-4">
            <div class="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
              <.simple_form for={@form} as={:service} id="service-form" phx-change="validate" phx-submit="save">
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
            </div>
          </section>

          <section :if={@live_action == :show and @service} class="space-y-4 px-4 py-4">
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
                  <.link patch={~p"/services/#{@service.id}/edit"} class={action_link_class()}>
                    Edit
                  </.link>
                  <.link patch={~p"/services/#{@service.id}/delete"} class={danger_action_link_class()}>
                    Delete
                  </.link>
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
                <div class="rounded-2xl bg-slate-50 px-4 py-4">
                  <dt class="text-xs font-semibold uppercase tracking-[0.18em] text-slate-400">Recurring</dt>
                  <dd class="mt-2 text-base font-semibold text-slate-900"><%= yes_no(@service.is_recurring) %></dd>
                </div>
                <div class="rounded-2xl bg-slate-50 px-4 py-4">
                  <dt class="text-xs font-semibold uppercase tracking-[0.18em] text-slate-400">Hide Duration</dt>
                  <dd class="mt-2 text-base font-semibold text-slate-900"><%= yes_no(@service.hide_duration) %></dd>
                </div>
              </dl>
            </article>
          </section>

          <section :if={@live_action == :delete and @service} class="px-4 py-4">
            <div class="rounded-3xl border border-danger-200 bg-danger-25 p-6 shadow-sm">
              <p class="text-xs font-semibold uppercase tracking-[0.18em] text-danger-700">Delete Service</p>
              <h2 class="mt-2 text-2xl font-semibold tracking-tight text-slate-950"><%= @service.name %></h2>
              <p class="mt-3 text-sm leading-6 text-slate-600">
                This deletes the service record. Any existing slots pointing at this service may become unusable.
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
                <.link patch={~p"/services/#{@service.id}"} class="rounded-full px-4 py-2 text-sm font-medium text-slate-500 transition hover:bg-white hover:text-slate-900">
                  Cancel
                </.link>
              </div>
            </div>
          </section>
        </main>

        <aside class="bg-slate-50 lg:min-h-screen lg:border-l lg:border-slate-200">
          <div class="space-y-4 px-4 py-4">
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

            <div class="rounded-3xl border border-slate-200 bg-white p-4 shadow-sm">
              <h2 class="text-lg font-semibold tracking-tight text-slate-950">Workflow</h2>
              <div class="mt-3 space-y-2 text-sm leading-6 text-slate-600">
                <p>Use the list page to review current offerings.</p>
                <p>Create and edit each service on its own page, then return to the show page to inspect the final result.</p>
                <p>Delete uses a dedicated confirmation page so removal is explicit.</p>
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
     |> assign(:service, nil)
     |> assign(:form, nil)
     |> assign(:services, [])
     |> assign(:stats, %{total: 0, active: 0, public: 0})
     |> assign(:page_title, "Services")}
  end

  def handle_params(params, _uri, socket) do
    services = Catalog.list_user_services(socket.assigns.current_user)

    socket =
      socket
      |> assign(:services, services)
      |> assign(:stats, service_stats(services))

    case socket.assigns.live_action do
      :index ->
        {:noreply,
         socket
         |> assign(:page_title, "My Services")
         |> assign(:service, nil)
         |> assign(:form, nil)}

      :new ->
        {:noreply,
         socket
         |> assign(:page_title, "Create Service")
         |> assign(:service, nil)
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
        case Catalog.create_user_service(socket.assigns.current_user, params) do
          {:ok, service} ->
            {:noreply,
             socket
             |> put_flash(:info, "Service created.")
             |> push_patch(to: ~p"/services/#{service.id}")}

          {:error, changeset} ->
            {:noreply, assign(socket, :form, to_form(Map.put(changeset, :action, :insert), as: :service))}
        end

      :edit ->
        case Catalog.update_user_service(socket.assigns.service, params) do
          {:ok, service} ->
            {:noreply,
             socket
             |> put_flash(:info, "Service updated.")
             |> push_patch(to: ~p"/services/#{service.id}")}

          {:error, changeset} ->
            {:noreply, assign(socket, :form, to_form(Map.put(changeset, :action, :update), as: :service))}
        end
    end
  end

  def handle_event("confirm_delete", _params, socket) do
    case Catalog.delete_user_service(socket.assigns.service) do
      {:ok, _service} ->
        {:noreply,
         socket
         |> put_flash(:info, "Service deleted.")
         |> push_patch(to: ~p"/services")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Service could not be deleted.")}
    end
  end

  defp load_service(socket, nil, _action) do
    {:noreply,
     socket
     |> put_flash(:error, "That service was not found.")
     |> push_patch(to: ~p"/services")}
  end

  defp load_service(socket, id, action) do
    case Catalog.get_user_service(socket.assigns.current_user, id) do
      nil ->
        {:noreply,
         socket
         |> put_flash(:error, "That service was not found.")
         |> push_patch(to: ~p"/services")}

      service ->
        socket =
          socket
          |> assign(:service, service)
          |> assign(:page_title, page_title(action, service))
          |> assign(:form, form_for_action(socket.assigns.current_user, action, service))

        {:noreply, socket}
    end
  end

  defp service_changeset_for_action(%{assigns: %{live_action: :new, current_user: user}}, params) do
    Catalog.change_user_service(user, %UserService{}, params)
  end

  defp service_changeset_for_action(%{assigns: %{current_user: user, service: service}}, params) do
    Catalog.change_user_service(user, service, params)
  end

  defp default_service_changeset(user) do
    Catalog.change_user_service(user, %UserService{}, %{
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
    |> Catalog.change_user_service(service)
    |> to_form(as: :service)
  end

  defp service_stats(services) do
    %{
      total: length(services),
      active: Enum.count(services, & &1.is_active),
      public: Enum.count(services, & &1.is_public)
    }
  end

  defp service_page_label(:index), do: "Read"
  defp service_page_label(:new), do: "Create"
  defp service_page_label(:show), do: "Read"
  defp service_page_label(:edit), do: "Update"
  defp service_page_label(:delete), do: "Delete"

  defp page_title(:show, service), do: service.name
  defp page_title(:edit, service), do: "Edit #{service.name}"
  defp page_title(:delete, service), do: "Delete #{service.name}"

  defp cancel_service_path(nil), do: ~p"/services"
  defp cancel_service_path(service), do: ~p"/services/#{service.id}"

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

  defp status_badge_class(true) do
    "rounded-full bg-emerald-50 px-2.5 py-1 text-[11px] font-semibold text-emerald-700"
  end

  defp status_badge_class(false) do
    "rounded-full bg-slate-100 px-2.5 py-1 text-[11px] font-semibold text-slate-500"
  end

  defp visibility_badge_class(true) do
    "rounded-full bg-brand-50 px-2.5 py-1 text-[11px] font-semibold text-brand-700"
  end

  defp visibility_badge_class(false) do
    "rounded-full bg-slate-100 px-2.5 py-1 text-[11px] font-semibold text-slate-500"
  end

  defp money(nil, currency), do: "0 #{currency || "KRW"}"

  defp money(price, currency) do
    "#{price} #{currency}"
  end

  defp yes_no(true), do: "Yes"
  defp yes_no(false), do: "No"
  defp yes_no(_), do: "No"

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

  defp present?(value), do: value not in [nil, ""]
end
