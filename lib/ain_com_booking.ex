defmodule AinComBooking do
  @moduledoc """
  AinCom keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def controller do
    quote do
      use Phoenix.Controller, namespace: AinComBookingWeb

      import AinComBookingWeb.Gettext
      import Plug.Conn

      alias AinComBookingWeb.Router.Helpers, as: Routes
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

  defmacro __using__(which) when is_atom(which), do: apply(__MODULE__, which, [])
end
