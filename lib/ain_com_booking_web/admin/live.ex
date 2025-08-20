defmodule AinComBookingWeb.Admin.Live do
  @moduledoc false
  use Phoenix.LiveView, layout: {AinComBookingWeb.Layouts, :live}

  def mount(_, _, socket) do
    {:ok, socket}
  end

  def render(assigns), do: AinComBookingWeb.Admin.HTML.index_live(assigns)
end
