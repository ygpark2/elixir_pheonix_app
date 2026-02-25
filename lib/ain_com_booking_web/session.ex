defmodule AinComBookingWeb.Session do
  @moduledoc false
  @behaviour Plug

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    Plug.Session.call(conn, Plug.Session.init(config()))
  end

  def config do
    [
      store: :cookie,
      key: app_config(:session_key),
      signing_salt: app_config(:session_signing_salt)
    ]
  end

  defp app_config(key) do
    Keyword.fetch!(Application.get_env(:ain_com_booking, AinComBookingWeb.Endpoint), key)
  end
end
