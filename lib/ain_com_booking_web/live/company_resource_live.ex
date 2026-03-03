defmodule AinComBookingWeb.CompanyResourceLive do
  @moduledoc false
  use AinComBookingWeb, :live_view

  import AinComBookingWeb.CompanyConsoleComponents

  alias AinComBooking.Catalog.CompanyResource
  alias AinComBooking.CompanyConsole

  @resource_type_options [
    {"Room", "room"},
    {"Equipment", "equipment"},
    {"Desk", "desk"},
    {"Studio", "studio"}
  ]

  def render(assigns) do
    ~H"""
    <.shell
      current_user={@current_user}
      company={@company}
      active_section={:resources}
      page_title={@page_title}
      page_label={resource_page_label(@live_action)}
      page_subtitle="Resources are bookable inventory. Attach booking pages under each resource when customers should reserve a specific room or asset."
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
                <h3 class="text-lg font-semibold tracking-tight text-slate-950">Booking Pages For This Resource</h3>
                <p class="mt-1 text-sm text-slate-500">Create customer-facing URLs tailored to this resource.</p>
              </div>
              <.link
                navigate={resource_booking_page_path(@resource.id, nil, :new)}
                class="inline-flex items-center gap-2 rounded-full bg-slate-950 px-4 py-2 text-sm font-semibold text-white transition hover:bg-slate-800"
              >
                <.icon name="hero-link" class="h-4 w-4" />
                <span>Create Booking Page</span>
              </.link>
            </div>

            <div :if={@booking_pages == []} class="mt-4 rounded-2xl border border-dashed border-slate-300 bg-slate-50 px-4 py-6 text-sm text-slate-500">
              No booking pages yet for this resource.
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
                    <.link navigate={resource_booking_page_path(@resource.id, page.id, :show)} class={action_link_class()}>Open</.link>
                  </div>
                </div>
              </div>
            </div>
          </section>
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
     |> assign(:booking_pages, [])
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
         |> assign(:booking_pages, [])
         |> assign(:form, nil)}

      :new ->
        {:noreply,
         socket
         |> assign(:page_title, "Create Company Resource")
         |> assign(:resource, nil)
         |> assign(:booking_pages, [])
         |> assign(:form, to_form(default_resource_changeset(socket.assigns.current_user), as: :resource))}

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
        booking_pages = CompanyConsole.list_booking_pages_for_resource(socket.assigns.current_user, resource.id)

        {:noreply,
         socket
         |> assign(:resource, resource)
         |> assign(:booking_pages, booking_pages)
         |> assign(:page_title, company_resource_page_title(action, resource))
         |> assign(:form, form_for_action(socket.assigns.current_user, action, resource))}
    end
  end

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

  defp resource_booking_page_path(resource_id, nil, :new), do: "/company/console/resources/#{resource_id}/pages/new"
  defp resource_booking_page_path(resource_id, page_id, :show), do: "/company/console/resources/#{resource_id}/pages/#{page_id}"
  defp resource_booking_page_path(resource_id, page_id, :edit), do: "/company/console/resources/#{resource_id}/pages/#{page_id}/edit"
  defp resource_booking_page_path(resource_id, page_id, :delete), do: "/company/console/resources/#{resource_id}/pages/#{page_id}/delete"

  defp action_link_class do
    "inline-flex items-center rounded-full px-3 py-2 text-sm font-medium text-slate-500 transition hover:bg-slate-100 hover:text-slate-900"
  end

  defp danger_action_link_class do
    "inline-flex items-center rounded-full px-3 py-2 text-sm font-medium text-danger-700 transition hover:bg-danger-50"
  end

  defp page_status_class(true), do: "rounded-full bg-emerald-50 px-2.5 py-1 text-[11px] font-semibold text-emerald-700"
  defp page_status_class(false), do: "rounded-full bg-slate-100 px-2.5 py-1 text-[11px] font-semibold text-slate-500"
  defp money(nil, currency), do: "0 #{currency || "KRW"}"
  defp money(price, currency), do: "#{price} #{currency}"
  defp present?(value), do: value not in [nil, ""]
end
