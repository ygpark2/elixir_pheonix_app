defmodule AinComBooking.Application do
  @moduledoc """
  Main entry point of the app
  """

  use Application

  def start(_type, _args) do
    children = [
      AinComBookingApi.Repo,
      {Phoenix.PubSub, [name: AinCom.PubSub, adapter: Phoenix.PubSub.PG2]},
      AinComBookingWeb.Endpoint,
      {TelemetryUI, AinCom.TelemetryUI.config()}
    ]

    :logger.add_handler(:sentry_handler, Sentry.LoggerHandler, %{})

    opts = [strategy: :one_for_one, name: AinCom.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    AinComWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
