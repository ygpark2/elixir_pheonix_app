defmodule AinComBookingWeb.Layouts do
  @moduledoc false
  use AinComBookingWeb, :html

  alias Phoenix.LiveView.JS

  # knobs the layout responds to
  attr(:variant, :atom, values: [:app, :auth, :settings, :main, :dashboard], default: :app)
  attr(:body_class, :string, default: nil)
  attr(:show_flash, :boolean, default: true)
  def root(assigns)

  attr(:flash, :map, required: true)
  attr(:kind, :atom, required: true)
  def layout_flash(assigns)

  embed_templates("layouts/*")

  def hide_flash(id) do
    "lv:clear-flash"
    |> JS.push()
    |> JS.hide(to: id)
  end

  # optional helper for body classes per variant
  def body_class_for(:auth), do: "min-h-screen grid place-items-center bg-gray-50"
  def body_class_for(:settings), do: "min-h-screen bg-slate-50"
  def body_class_for(:main), do: "min-h-screen bg-white"
  def body_class_for(:dashboard), do: "min-h-screen bg-white"
  def body_class_for(:app), do: "min-h-screen"
end
