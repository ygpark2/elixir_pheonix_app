defmodule AinComBookingWeb.Admin.Controller do
  use Phoenix.Controller

  plug(:put_view, AinComBookingWeb.Admin.HTML)

  @spec index(Plug.Conn.t(), map) :: Plug.Conn.t()
  def index(conn, _) do
    conn
    |> assign(:variant, :main)
    |> assign(:body_class, "main")
    |> assign(:title, "Dashboard")
    |> render(:index, message: "Hello, world!")
  end
end
