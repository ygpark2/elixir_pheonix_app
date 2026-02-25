defmodule AinComBookingWeb.AdminComponents do
  @moduledoc false
  use Phoenix.Component

  embed_templates("admin/*")

  attr(:menu_toggle, :boolean, default: false)
  attr(:sidebar_toggle, :boolean, default: false)
  attr(:dark_mode, :boolean, default: false)
  def header(assigns)

  def sidebar(assigns)

  def preloader(assigns)
end
