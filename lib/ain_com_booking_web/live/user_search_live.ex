defmodule AinComBookingWeb.UserSearchLive do
  @moduledoc false
  use AinComBookingWeb, :live_view

  alias AinComBooking.Accounts

  def render(assigns) do
    ~H"""
    <.header class="text-center">
      User Search
      <:subtitle>Find users by name or ID</:subtitle>
    </.header>

    <div class="mx-auto max-w-2xl space-y-6 p-4">
      <.simple_form
        for={@form}
        as={:search}
        id="user_search_form"
        phx-change="search"
        phx-submit="search"
      >
        <.input
          field={@form[:query]}
          type="text"
          label="Search"
          placeholder="Search by name or ID"
        />
        <:actions>
          <.button phx-disable-with="Searching...">Search</.button>
        </:actions>
      </.simple_form>

      <div>
        <p :if={@query != "" and @results == []} class="text-sm text-zinc-500">
          No results found
        </p>
        <ul :if={@results != []} class="space-y-2">
          <li :for={user <- @results} class="rounded-lg bg-white p-3">
            <div class="font-semibold text-zinc-800"><%= user.name %></div>
            <div class="text-xs text-zinc-500"><%= user.id %></div>
          </li>
        </ul>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    form = to_form(%{"query" => ""}, as: :search)

    {:ok, assign(socket, form: form, query: "", results: [])}
  end

  def handle_event("search", %{"search" => %{"query" => query}}, socket) do
    trimmed = String.trim(query || "")

    results =
      if trimmed == "" do
        []
      else
        Accounts.search_users(socket.assigns.current_user, trimmed)
      end

    form = to_form(%{"query" => query}, as: :search)

    {:noreply, assign(socket, form: form, query: trimmed, results: results)}
  end
end
