defmodule AinComBookingWeb.UserProfileLive do
  @moduledoc false
  use AinComBookingWeb, :live_view

  alias AinComBooking.Accounts

  def render(assigns) do
    ~H"""
    <.header class="text-center">
      User Profile
      <:subtitle>Connect and follow schedules</:subtitle>
    </.header>

    <div class="mx-auto max-w-2xl space-y-6 p-4">
      <div class="rounded-lg bg-white p-4">
        <div class="text-lg font-semibold text-zinc-800"><%= @user.name %></div>
        <div class="text-xs text-zinc-500"><%= @user.id %></div>

        <p class="mt-3 text-sm text-zinc-600">
          <%= if @following, do: "Following", else: "Not following" %>
        </p>

        <div :if={@show_follow_action} class="mt-3">
          <.button id="follow-toggle" phx-click="toggle_follow" phx-disable-with="Updating...">
            <%= if @following, do: "Unfollow", else: "Follow" %>
          </.button>
        </div>
      </div>

      <div class="rounded-lg bg-white p-4">
        <h3 class="text-sm font-semibold text-zinc-800">Schedule</h3>
        <%!-- TODO: Connect follower-only schedule visibility once schedule sharing is implemented. --%>
        <p :if={@following} class="mt-2 text-sm text-zinc-600">
          Follower schedule visible
        </p>
        <p :if={!@following} class="mt-2 text-sm text-zinc-600">
          Follow to see schedule
        </p>
      </div>
    </div>
    """
  end

  def mount(%{"id" => user_id}, _session, socket) do
    user = Accounts.get_user!(user_id)
    current_user = socket.assigns.current_user

    following = Accounts.following?(current_user, user)

    {:ok,
     assign(socket,
       user: user,
       following: following,
       show_follow_action: current_user.id != user.id
     )}
  end

  def handle_event("toggle_follow", _params, socket) do
    current_user = socket.assigns.current_user
    user = socket.assigns.user

    if socket.assigns.following do
      :ok = Accounts.unfollow_user(current_user, user)
    else
      _ = Accounts.follow_user(current_user, user)
    end

    {:noreply, assign(socket, following: Accounts.following?(current_user, user))}
  end
end
