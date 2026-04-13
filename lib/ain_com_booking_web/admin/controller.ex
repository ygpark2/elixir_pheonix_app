defmodule AinComBookingWeb.Admin.Controller do
  use Phoenix.Controller, formats: [html: AinComBookingWeb.Admin.HTML]

  @spec index(Plug.Conn.t(), map) :: Plug.Conn.t()
  def index(conn, _) do
    redirect(conn, to: "/admin/dashboard")
  end
end
