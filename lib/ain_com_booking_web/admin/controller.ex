defmodule AinComBookingWeb.Admin.Controller do
  use Phoenix.Controller

  plug(:put_view, AinComBookingWeb.Admin.HTML)

  @spec index(Plug.Conn.t(), map) :: Plug.Conn.t()
  def index(conn, _) do
    # <%= render "partials/header.html", assigns |> Map.merge(%{title: "Dashboard", user: @current_user}) %>
    conn
    |> assign(:variant, :main)
    |> assign(:body_class, "main")
    |> Map.merge(%{title: "Dashboard", sidebarToggle: true})
    |> render(:index, message: "Hello, world!")
  end
end
