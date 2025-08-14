defmodule AinComBookingWeb do
  @moduledoc """
  AinCom keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def controller do
    quote do
      use Phoenix.Controller, namespace: AinComBookingWeb

      import AinComBooking.Gettext
      import Plug.Conn

      alias AinComBookingWeb.Router.Helpers, as: Routes

      unquote(verified_routes())
    end
  end

  def html do
    quote do
      use Phoenix.Component

      import AinComBooking.Gettext
      import AinComBookingWeb.CoreComponents
      import Phoenix.HTML
      import Phoenix.HTML.Form
      # import Phoenix.HTML.Tag

      alias AinComBookingWeb.Router.Helpers, as: Routes

      unquote(verified_routes())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {AinComBookingWeb.Layouts, :app}

      import AinComBookingWeb.CoreComponents
      import Phoenix.Component

      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: AinComBookingWeb.Endpoint,
        router: AinComBookingWeb.Router,
        statics: AinComBookingWeb.static_paths()
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/ain_com_booking_web/templates",
        namespace: AinComBookingWeb

      import AinComBookingWeb.ErrorHelpers
      import AinComBookingWeb.Gettext

      import Phoenix.Controller,
        only: [get_flash: 1, get_flash: 2, view_module: 1]

      alias AinComBookingWeb.Router.Helpers, as: Routes
    end
  end

  def router do
    quote do
      use Phoenix.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel

      import AinComBookingWeb.Gettext
    end
  end

  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  defmacro __using__(which) when is_atom(which), do: apply(__MODULE__, which, [])
end
