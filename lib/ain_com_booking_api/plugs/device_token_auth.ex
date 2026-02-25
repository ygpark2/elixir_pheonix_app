defmodule AinComBookingApi.Plugs.DeviceTokenAuth do
  @moduledoc false
  import Plug.Conn

  alias AinComBookingApi.Devices

  @header "x-device-token"

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_req_header(conn, @header) do
      [raw] when byte_size(raw) > 0 ->
        with {:ok, device} <- Devices.get_by_raw_token_ok(raw),
             :ok <- Devices.valid?(device) do
          ip = parse_ip(conn)
          ua = conn |> get_req_header("user-agent") |> List.first()
          _ = Devices.touch_seen(device, ip, ua)
          assign(conn, :current_device, device)
        else
          {:error, :expired} -> unauthorized(conn, "device token expired")
          {:error, :revoked} -> forbidden(conn, "device revoked")
          _ -> unauthorized(conn, "invalid device token")
        end

      _ ->
        unauthorized(conn, "missing device token")
    end
  end

  defp parse_ip(conn) do
    forwarded = conn |> get_req_header("x-forwarded-for") |> List.first()

    cond do
      forwarded && forwarded != "" -> forwarded |> String.split(",") |> List.first() |> String.trim()
      conn.remote_ip -> conn.remote_ip |> :inet.ntoa() |> to_string()
      true -> nil
    end
  end

  defp unauthorized(conn, msg) do
    conn
    |> put_status(:unauthorized)
    |> Phoenix.Controller.json(%{error: "unauthorized", reason: msg})
    |> halt()
  end

  defp forbidden(conn, msg) do
    conn
    |> put_status(:forbidden)
    |> Phoenix.Controller.json(%{error: "forbidden", reason: msg})
    |> halt()
  end
end
