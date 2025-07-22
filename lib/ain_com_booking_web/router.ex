defmodule AinComBookingWeb.Router do
  # use AinComBookingWeb, :router
  use Pow.Phoenix.Router

  use Pow.Extension.Phoenix.Router,
    extensions: [PowEmailConfirmation, PowPersistentSession, PowResetPassword]

  use Phoenix.Router

  import Phoenix.LiveView.Router

  pipeline :api do
    plug(:accepts, ["json"])

    plug(:session)
    plug(:fetch_session)

    # 선택 사항 (예: Pow 등에서 사용)
    # plug(:fetch_current_user)
  end

  pipeline :browser do
    plug(:accepts, ["html", "json"])

    plug(:session)
    plug(:fetch_session)

    plug(:protect_from_forgery)
    plug(:fetch_live_flash)

    plug(:put_layout, {AinComBookingWeb.Layouts, :app})
    plug(:put_root_layout, {AinComBookingWeb.Layouts, :root})
  end

  scope "/" do
    pipe_through(:browser)

    pow_routes()
    pow_extension_routes()

    # To enable metrics dashboard use `telemetry_ui_allowed: true` as assigns value
    #
    # Metrics can contains sensitive data you should protect it under authorization
    # See https://github.com/mirego/telemetry_ui#security
    get("/metrics", TelemetryUI.Web, [], assigns: %{telemetry_ui_allowed: true})
  end

  scope "/", AinComBookingWeb do
    pipe_through(:browser)

    get("/", Home.Controller, :index, as: :home)
  end

  scope "/", AinComBookingWeb do
    pipe_through(:browser)

    live("/live", Home.Live, :index, as: :live_home)
  end

  scope "/api", AinComBookingApiWeb do
    pipe_through(:api)

    post("/auth/signup", AuthController, :signup)
    post("/auth/login", AuthController, :login)

    get("/slots", SlotController, :index)
    post("/bookings", BookingController, :create)
    get("/bookings", BookingController, :index)
    delete("/bookings/:id", BookingController, :delete)
  end

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  defp session(conn, _opts) do
    opts = Plug.Session.init(AinComBookingWeb.Session.config())
    Plug.Session.call(conn, opts)
  end
end
