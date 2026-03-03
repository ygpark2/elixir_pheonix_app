defmodule AinComBookingWeb.UserResourceLive do
  @moduledoc false
  use AinComBookingWeb, :live_view

  alias AinComBooking.Catalog
  alias AinComBooking.Catalog.UserResource

  @resource_type_options [
    {"Room", "room"},
    {"Equipment", "equipment"},
    {"Desk", "desk"},
    {"Studio", "studio"}
  ]

  def render(assigns) do
    ~H"""
    <style id="user-resource-live-style">
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
              <div class="text-xs font-semibold uppercase tracking-[0.22em] text-brand-600">Resources</div>
              <div class="mt-3 text-2xl font-semibold tracking-tight text-slate-950">Manage Resources</div>
              <p class="mt-2 text-sm leading-6 text-slate-500">
                Split resource management into dedicated create, read, update, and delete pages.
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
              <.link navigate={~p"/slots"} class={console_nav_class(false)}>
                <.icon name="hero-calendar-days" class="h-5 w-5" />
                <span class="text-sm font-semibold">Slots</span>
              </.link>
              <.link patch={~p"/resources"} class={console_nav_class(true)}>
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
                <p class="mt-0.5 text-xs font-medium uppercase tracking-[0.18em] text-slate-400"><%= resource_page_label(@live_action) %></p>
              </div>

              <.link
                :if={@live_action != :new}
                patch={~p"/resources/new"}
                class="inline-flex items-center gap-2 rounded-full bg-brand-600 px-4 py-2 text-sm font-semibold text-white transition hover:bg-brand-500"
              >
                <.icon name="hero-plus" class="h-4 w-4" />
                <span>New Resource</span>
              </.link>
            </div>
          </div>

          <section :if={@live_action == :index} class="space-y-4 px-4 py-4">
            <div :if={@resources == []} class="rounded-3xl border border-dashed border-slate-300 bg-slate-50 px-6 py-10 text-center text-sm text-slate-500">
              No resources yet. Add your first resource so followers can book against it.
            </div>

            <article
              :for={resource <- @resources}
              id={"resource-#{resource.id}"}
              class="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm"
            >
              <div class="flex flex-wrap items-start justify-between gap-4">
                <div class="min-w-0 flex-1">
                  <div class="flex flex-wrap items-center gap-2">
                    <h2 class="text-lg font-semibold tracking-tight text-slate-950"><%= resource.name %></h2>
                    <span class="rounded-full bg-slate-100 px-2.5 py-1 text-[11px] font-semibold text-slate-600">
                      <%= resource.type %>
                    </span>
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
                  <.link patch={~p"/resources/#{resource.id}"} class={action_link_class()}>
                    View
                  </.link>
                  <.link patch={~p"/resources/#{resource.id}/edit"} class={action_link_class()}>
                    Edit
                  </.link>
                  <.link patch={~p"/resources/#{resource.id}/delete"} class={danger_action_link_class()}>
                    Delete
                  </.link>
                </div>
              </div>
            </article>
          </section>

          <section :if={@live_action == :new or @live_action == :edit} class="px-4 py-4">
            <div class="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
              <.simple_form for={@form} as={:resource} id="resource-form" phx-change="validate" phx-submit="save">
                <div class="grid gap-4 md:grid-cols-2">
                  <.input field={@form[:name]} type="text" label="Name" />
                  <.input
                    field={@form[:type]}
                    type="select"
                    label="Type"
                    prompt="Choose a type"
                    options={@resource_type_options}
                  />
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
            </div>
          </section>

          <section :if={@live_action == :show and @resource} class="space-y-4 px-4 py-4">
            <article class="rounded-3xl border border-slate-200 bg-white p-6 shadow-sm">
              <div class="flex flex-wrap items-start justify-between gap-4">
                <div class="min-w-0 flex-1">
                  <div class="flex flex-wrap items-center gap-2">
                    <h2 class="text-2xl font-semibold tracking-tight text-slate-950"><%= @resource.name %></h2>
                    <span class="rounded-full bg-slate-100 px-2.5 py-1 text-[11px] font-semibold text-slate-600">
                      <%= @resource.type %>
                    </span>
                  </div>
                  <p :if={present?(@resource.description)} class="mt-3 text-sm leading-7 text-slate-600"><%= @resource.description %></p>
                </div>

                <div class="flex flex-wrap items-center gap-2">
                  <.link patch={~p"/resources/#{@resource.id}/edit"} class={action_link_class()}>
                    Edit
                  </.link>
                  <.link patch={~p"/resources/#{@resource.id}/delete"} class={danger_action_link_class()}>
                    Delete
                  </.link>
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
          </section>

          <section :if={@live_action == :delete and @resource} class="px-4 py-4">
            <div class="rounded-3xl border border-danger-200 bg-danger-25 p-6 shadow-sm">
              <p class="text-xs font-semibold uppercase tracking-[0.18em] text-danger-700">Delete Resource</p>
              <h2 class="mt-2 text-2xl font-semibold tracking-tight text-slate-950"><%= @resource.name %></h2>
              <p class="mt-3 text-sm leading-6 text-slate-600">
                This removes the resource record. Existing slots attached to it may become invalid.
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
                <.link patch={~p"/resources/#{@resource.id}"} class="rounded-full px-4 py-2 text-sm font-medium text-slate-500 transition hover:bg-white hover:text-slate-900">
                  Cancel
                </.link>
              </div>
            </div>
          </section>
        </main>

        <aside class="bg-slate-50 lg:min-h-screen lg:border-l lg:border-slate-200">
          <div class="space-y-4 px-4 py-4">
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

            <div class="rounded-3xl border border-slate-200 bg-white p-4 shadow-sm">
              <h2 class="text-lg font-semibold tracking-tight text-slate-950">Workflow</h2>
              <div class="mt-3 space-y-2 text-sm leading-6 text-slate-600">
                <p>Use the list page for read access to everything you own.</p>
                <p>Create and edit resources on dedicated pages to keep the booking setup explicit.</p>
                <p>Delete uses its own confirmation route before removal.</p>
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
     |> assign(:resource_type_options, @resource_type_options)
     |> assign(:resource, nil)
     |> assign(:form, nil)
     |> assign(:resources, [])
     |> assign(:stats, %{total: 0, located: 0, priced: 0})
     |> assign(:page_title, "Resources")}
  end

  def handle_params(params, _uri, socket) do
    resources = Catalog.list_user_resources(socket.assigns.current_user)

    socket =
      socket
      |> assign(:resources, resources)
      |> assign(:stats, resource_stats(resources))

    case socket.assigns.live_action do
      :index ->
        {:noreply,
         socket
         |> assign(:page_title, "My Resources")
         |> assign(:resource, nil)
         |> assign(:form, nil)}

      :new ->
        {:noreply,
         socket
         |> assign(:page_title, "Create Resource")
         |> assign(:resource, nil)
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
        case Catalog.create_user_resource(socket.assigns.current_user, params) do
          {:ok, resource} ->
            {:noreply,
             socket
             |> put_flash(:info, "Resource created.")
             |> push_patch(to: ~p"/resources/#{resource.id}")}

          {:error, changeset} ->
            {:noreply, assign(socket, :form, to_form(Map.put(changeset, :action, :insert), as: :resource))}
        end

      :edit ->
        case Catalog.update_user_resource(socket.assigns.resource, params) do
          {:ok, resource} ->
            {:noreply,
             socket
             |> put_flash(:info, "Resource updated.")
             |> push_patch(to: ~p"/resources/#{resource.id}")}

          {:error, changeset} ->
            {:noreply, assign(socket, :form, to_form(Map.put(changeset, :action, :update), as: :resource))}
        end
    end
  end

  def handle_event("confirm_delete", _params, socket) do
    case Catalog.delete_user_resource(socket.assigns.resource) do
      {:ok, _resource} ->
        {:noreply,
         socket
         |> put_flash(:info, "Resource deleted.")
         |> push_patch(to: ~p"/resources")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Resource could not be deleted.")}
    end
  end

  defp load_resource(socket, nil, _action) do
    {:noreply,
     socket
     |> put_flash(:error, "That resource was not found.")
     |> push_patch(to: ~p"/resources")}
  end

  defp load_resource(socket, id, action) do
    case Catalog.get_user_resource(socket.assigns.current_user, id) do
      nil ->
        {:noreply,
         socket
         |> put_flash(:error, "That resource was not found.")
         |> push_patch(to: ~p"/resources")}

      resource ->
        socket =
          socket
          |> assign(:resource, resource)
          |> assign(:page_title, page_title(action, resource))
          |> assign(:form, form_for_action(socket.assigns.current_user, action, resource))

        {:noreply, socket}
    end
  end

  defp resource_changeset_for_action(%{assigns: %{live_action: :new, current_user: user}}, params) do
    Catalog.change_user_resource(user, %UserResource{}, params)
  end

  defp resource_changeset_for_action(%{assigns: %{current_user: user, resource: resource}}, params) do
    Catalog.change_user_resource(user, resource, params)
  end

  defp default_resource_changeset(user) do
    Catalog.change_user_resource(user, %UserResource{}, %{
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
    |> Catalog.change_user_resource(resource)
    |> to_form(as: :resource)
  end

  defp resource_stats(resources) do
    %{
      total: length(resources),
      located: Enum.count(resources, &present?(&1.location)),
      priced: Enum.count(resources, &(not is_nil(&1.price)))
    }
  end

  defp resource_page_label(:index), do: "Read"
  defp resource_page_label(:new), do: "Create"
  defp resource_page_label(:show), do: "Read"
  defp resource_page_label(:edit), do: "Update"
  defp resource_page_label(:delete), do: "Delete"

  defp page_title(:show, resource), do: resource.name
  defp page_title(:edit, resource), do: "Edit #{resource.name}"
  defp page_title(:delete, resource), do: "Delete #{resource.name}"

  defp cancel_resource_path(nil), do: ~p"/resources"
  defp cancel_resource_path(resource), do: ~p"/resources/#{resource.id}"

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

  defp money(nil, currency), do: "0 #{currency || "KRW"}"

  defp money(price, currency) do
    "#{price} #{currency}"
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

  defp present?(value), do: value not in [nil, ""]
end
