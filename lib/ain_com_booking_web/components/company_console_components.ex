defmodule AinComBookingWeb.CompanyConsoleComponents do
  @moduledoc false
  use AinComBookingWeb, :html

  attr(:current_user, :map, required: true)
  attr(:company, :map, required: true)
  attr(:active_section, :atom, required: true)
  attr(:page_title, :string, required: true)
  attr(:page_label, :string, default: nil)
  attr(:page_subtitle, :string, default: nil)
  slot(:inner_block, required: true)
  slot(:sidebar)

  def shell(assigns) do
    ~H"""
    <style id="company-console-style">
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
      <div class="mx-auto grid max-w-7xl gap-0 lg:grid-cols-[240px_minmax(0,1fr)]">
        <aside class="border-b border-slate-200 bg-slate-50 lg:min-h-screen lg:border-b-0 lg:border-r">
          <div class="flex h-full flex-col gap-4 px-4 py-4">
            <div class="rounded-3xl border border-slate-200 bg-white px-4 py-5 shadow-sm">
              <div class="text-xs font-semibold uppercase tracking-[0.22em] text-brand-600">Company Console</div>
              <div class="mt-3 text-2xl font-semibold tracking-tight text-slate-950"><%= @company.name || "Company" %></div>
              <p class="mt-2 text-sm leading-6 text-slate-500">
                Paid company customers manage services, resources, availability, and published booking pages from one place.
              </p>
            </div>

            <nav class="space-y-2 rounded-3xl border border-slate-200 bg-white p-3 shadow-sm">
              <.link navigate={~p"/company/console"} class={nav_item_class(@active_section == :dashboard)}>
                <.icon name="hero-squares-2x2" class="h-5 w-5" />
                <span class="text-sm font-semibold">Dashboard</span>
              </.link>
              <.link navigate={~p"/company/console/services"} class={nav_item_class(@active_section == :services)}>
                <.icon name="hero-briefcase" class="h-5 w-5" />
                <span class="text-sm font-semibold">Services</span>
              </.link>
              <.link navigate={~p"/company/console/resources"} class={nav_item_class(@active_section == :resources)}>
                <.icon name="hero-cube" class="h-5 w-5" />
                <span class="text-sm font-semibold">Resources</span>
              </.link>
              <.link navigate={~p"/company/console/slots"} class={nav_item_class(@active_section == :slots)}>
                <.icon name="hero-calendar-days" class="h-5 w-5" />
                <span class="text-sm font-semibold">Slots</span>
              </.link>
              <.link navigate={~p"/company/console/pages"} class={nav_item_class(@active_section == :pages)}>
                <.icon name="hero-globe-alt" class="h-5 w-5" />
                <span class="text-sm font-semibold">Booking Pages</span>
              </.link>
            </nav>

            <section class="rounded-3xl border border-slate-200 bg-white p-3 shadow-sm">
              <div class="flex items-center gap-3 rounded-2xl px-2 py-2">
                <div class="flex h-11 w-11 shrink-0 items-center justify-center rounded-full bg-slate-950 text-sm font-semibold text-white">
                  <%= initials(@current_user.name) %>
                </div>

                <div class="min-w-0 flex-1">
                  <div class="truncate text-sm font-semibold text-slate-950"><%= @current_user.name || "Company User" %></div>
                  <div class="truncate text-xs text-slate-400"><%= @current_user.email %></div>
                </div>
              </div>

              <div class="mt-2 space-y-1">
                <.link
                  navigate={~p"/users/settings"}
                  class="flex items-center gap-3 rounded-2xl px-3 py-2 text-sm font-medium text-slate-500 transition hover:bg-slate-100 hover:text-slate-900"
                >
                  <.icon name="hero-cog-6-tooth" class="h-5 w-5" />
                  <span>Settings</span>
                </.link>
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

        <main class="min-w-0 bg-white lg:min-h-screen">
          <div class="sticky top-0 z-10 border-b border-slate-200 bg-white/90 px-5 py-4 backdrop-blur">
            <div class="flex flex-wrap items-center justify-between gap-3">
              <div>
                <h1 class="text-2xl font-semibold tracking-tight text-slate-950"><%= @page_title %></h1>
                <p :if={@page_label} class="mt-1 text-xs font-medium uppercase tracking-[0.18em] text-slate-400"><%= @page_label %></p>
                <p :if={@page_subtitle} class="mt-2 text-sm leading-6 text-slate-500"><%= @page_subtitle %></p>
              </div>
            </div>
          </div>

          <div class="grid gap-0 xl:grid-cols-[minmax(0,1fr)_320px]">
            <section class="min-w-0 border-b border-slate-200 px-5 py-5 xl:border-b-0 xl:border-r">
              <%= render_slot(@inner_block) %>
            </section>

            <aside :if={@sidebar != []} class="bg-slate-50 px-5 py-5">
              <%= render_slot(@sidebar) %>
            </aside>
          </div>
        </main>
      </div>
    </div>
    """
  end

  defp nav_item_class(true), do: "flex items-center gap-3 rounded-2xl bg-slate-950 px-4 py-3 text-white transition"

  defp nav_item_class(false) do
    "flex items-center gap-3 rounded-2xl px-4 py-3 text-slate-500 transition hover:bg-slate-100 hover:text-slate-900"
  end

  defp initials(name) do
    name
    |> to_string()
    |> String.split(~r/\s+/, trim: true)
    |> Enum.take(2)
    |> Enum.map_join("", &String.first/1)
    |> case do
      "" -> "C"
      initials -> String.upcase(initials)
    end
  end
end
