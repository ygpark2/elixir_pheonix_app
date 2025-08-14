defmodule AinComBookingWeb.Admin.Controller do
  use Phoenix.Controller

  plug(:put_view, AinComBookingWeb.Admin.HTML)

  @spec index(Plug.Conn.t(), map) :: Plug.Conn.t()
  def index(conn, _) do
    conn
    |> assign(:variant, :main)
    |> assign(:body_class, "main")
    |> assign(:title, "Dashboard")
    |> assign(:sidebar_toggle, true)
    |> assign(:menu_toggle, false)
    |> assign(:dark_mode, false)
    |> assign(:notification_dropdown_open, false)
    |> assign(:notifying, true)
    |> assign(:user_dropdown_open, false)
    |> render(:index, message: "Hello, world!")
  end
end
