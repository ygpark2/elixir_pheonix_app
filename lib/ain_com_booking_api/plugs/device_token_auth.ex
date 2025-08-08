defmodule AinComBookingApi.Plugs.DeviceTokenAuth do
  @moduledoc false
  import Plug.Conn

  alias AinComBookingApi.Devices

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_req_header(conn, "device_token") do
      [token] ->
        case Devices.get_device_by_token(token) do
          {:ok, device} ->
            assign(conn, :current_device, device)

          _ ->
            unauthorized(conn)
        end

      _ ->
        unauthorized(conn)
    end
  end

  def unauthorized(conn) do
    conn
    |> Plug.Conn.put_status(:unauthorized)
    |> Phoenix.Controller.json(%{error: "Unauthorized"})
  end

  # defp unauthorized(conn) do
  #   conn
  #   |> Phoenix.Controller.put_status(:unauthorized)
  #   |> Phoenix.Controller.json(%{error: "invalid device token"})
  #   |> halt()
  # end
end
