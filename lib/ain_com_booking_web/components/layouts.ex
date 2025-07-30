defmodule AinComBookingWeb.Layouts do
  @moduledoc false
  # use AinComBookingWeb, :html
  use Phoenix.Component

  alias AinComBookingWeb.Router.Helpers, as: Routes
  alias Phoenix.LiveView.JS

  embed_templates("layouts/*")

  attr(:flash, :map, required: true)
  attr(:kind, :atom, required: true)
  def flash(assigns)

  def hide_flash(id) do
    "lv:clear-flash"
    |> JS.push()
    |> JS.hide(to: id)
  end
end
