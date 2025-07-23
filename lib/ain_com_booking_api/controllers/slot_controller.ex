defmodule AinComBookingWeb.Controllers.SlotController do
  use Phoenix.Controller

  import AinComBookingWeb.Errors
  import Ecto.Query

  alias AinComBookingApi.Bookings.Slot
  alias AinComBookingApi.Repo

  def index(conn, %{"service_id" => _service_id, "from" => from_str, "to" => to_str}) do
    {:ok, from_date} = Date.from_iso8601(from_str)
    {:ok, to_date} = Date.from_iso8601(to_str)

    slots =
      Repo.all(
        from(s in Slot,
          where:
            s.start_time >= ^DateTime.new!(from_date, ~T[00:00:00], "Asia/Seoul") and s.start_time <= ^DateTime.new!(to_date, ~T[23:59:59], "Asia/Seoul") and
              s.status == "available"
        )
      )

    json(conn, slots)
  end
end
