defmodule AinComBookingWeb.Router do
  # use AinComBookingWeb, :router
  use Phoenix.Router

  import AinComBookingWeb.UserAuth
  import Phoenix.LiveDashboard.Router
  import Phoenix.LiveView.Router

  alias Company.CompanyBookingController
  alias Company.CompanyController
  alias Company.CompanyResourceController
  alias Company.CompanyServiceController
  alias Company.CompanySlotController
  alias Company.CompanyUnitController
  alias User.UserBookingController
  alias User.UserResourceController
  alias User.UserServiceController
  alias User.UserSlotController

  pipeline :api do
    plug(:accepts, ["json"])
    plug(:fetch_session)

    # 선택 사항 (예: Pow 등에서 사용)
    # plug(:fetch_current_user)
  end

  pipeline :protected_api do
    # JWT 검증
    plug(AinComBookingApi.AuthPipeline)
    # X-Device-Token 검증
    plug(AinComBookingApi.Plugs.DeviceTokenAuth)
  end

  pipeline :browser do
    plug(:accepts, ["html", "json"])
    plug(:fetch_session)
    plug(:fetch_current_user)

    plug(:protect_from_forgery)
    plug(:fetch_live_flash)

    plug(:put_layout, {AinComBookingWeb.Layouts, :app})
    plug(:put_root_layout, {AinComBookingWeb.Layouts, :root})
  end

  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through(:browser)

      live_dashboard("/dashboard",
        ecto_repos: [AinComBooking.Repo],
        ecto_psql_extras_options: [long_running_queries: [threshold: "200 milliseconds"]]
      )

      forward("/mailbox", Plug.Swoosh.MailboxPreview)

      # To enable metrics dashboard use `telemetry_ui_allowed: true` as assigns value
      #
      # Metrics can contains sensitive data you should protect it under authorization
      # See https://github.com/mirego/telemetry_ui#security
      get("/metrics", TelemetryUI.Web, [], assigns: %{telemetry_ui_allowed: true})
    end
  end

  scope "/", AinComBookingWeb do
    pipe_through(:browser)

    get("/", Home.Controller, :index, as: :home)
    live("/live", Home.Live, :index, as: :live_home)

    get("/admin", Admin.Controller, :index, as: :admin)
    live("/admin/live", Admin.Live, :index, as: :live_admin)
  end

  scope "/api", AinComBookingApi.Controllers do
    pipe_through(:api)

    post("/auth/signup", AuthController, :signup)
    post("/auth/login", AuthController, :login)

    pipe_through(:protected_api)

    resources("/company/companies", CompanyController, only: [:create, :update, :delete, :index])
    resources("/company/units", CompanyUnitController, only: [:create, :update, :delete, :index])
    resources("/company/slots", CompanySlotController, only: [:create, :update, :delete, :index])
    resources("/company/bookings", CompanyBookingController, only: [:create, :update, :delete, :index])
    resources("/company/services", CompanyServiceController, only: [:create, :update, :delete, :index])
    resources("/company/resources", CompanyResourceController, only: [:create, :update, :delete, :index])

    resources("/user/slots", UserSlotController, only: [:create, :update, :delete, :index])
    resources("/user/bookings", UserBookingController, only: [:create, :update, :delete, :index])
    resources("/user/services", UserServiceController, only: [:create, :update, :delete, :index])
    resources("/user/resources", UserResourceController, only: [:create, :update, :delete, :index])
  end

  scope "/api/swagger" do
    forward("/", PhoenixSwagger.Plug.SwaggerUI,
      otp_app: :ain_com_booking,
      swagger_file: "swagger.json"
    )
  end

  # Swagger 설명 정보
  def swagger_info do
    %{
      info: %{
        version: "1.0",
        title: "AinComBooking API"
      },
      basePath: "/api",
      consumes: ["application/json"],
      produces: ["application/json"],
      tags: [
        %{
          name: "Company",
          description: "Company-related endpoints"
        },
        %{
          name: "User",
          description: "User-related endpoints"
        }
      ]
    }
  end

  ## Authentication routes
  scope "/", AinComBookingWeb do
    pipe_through([:browser, :redirect_if_user_is_authenticated])

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{AinComBookingWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live("/users/register", UserRegistrationLive, :new)
      live("/users/log_in", UserLoginLive, :new)
      live("/users/reset_password", UserForgotPasswordLive, :new)
      live("/users/reset_password/:token", UserResetPasswordLive, :edit)
    end

    post("/users/log_in", UserSessionController, :create)
  end

  scope "/", AinComBookingWeb do
    pipe_through([:browser, :require_authenticated_user])

    live_session :require_authenticated_user,
      on_mount: [{AinComBookingWeb.UserAuth, :ensure_authenticated}] do
      live("/admin/dashboard", AdminDashboardLive, :index)
      live("/feed", SocialFeedLive, :index)
      live("/users/search", UserSearchLive, :index)
      live("/users/settings", UserSettingsLive, :edit)
      live("/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email)
      live("/profiles/:id", UserProfileLive, :show)
    end
  end

  scope "/", AinComBookingWeb do
    pipe_through([:browser])

    # Fallback route for clients that issue GET requests (e.g. stale JS/cached pages).
    get("/users/log_out", UserSessionController, :delete)
    delete("/users/log_out", UserSessionController, :delete)

    live_session :current_user,
      on_mount: [{AinComBookingWeb.UserAuth, :mount_current_user}] do
      live("/users/confirm/:token", UserConfirmationLive, :edit)
      live("/users/confirm", UserConfirmationInstructionsLive, :new)
    end
  end
end
