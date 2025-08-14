defmodule AinComBookingWeb.Home.Controller do
  use Phoenix.Controller

  plug(:put_view, AinComBookingWeb.Home.HTML)

  @spec index(Plug.Conn.t(), map) :: Plug.Conn.t()
  def index(conn, _) do
    conn
    |> assign(:variant, :main)
    |> assign(:body_class, "main")
    |> render(:index, message: "Hello, world!")
  end
end
