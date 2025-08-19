defmodule AinComBookingWeb.Admin.HTML do
  use Phoenix.Component

  embed_templates("templates/**/*")

  def render("index.html", assigns), do: index(assigns)

  attr(:text, :string, required: true)
  def message(assigns)

  attr(:url, :string, default: "https://github.com/mirego/ain-com")
  def header(assigns)

  """
  def partials_header(assigns) do
    assigns =
      assigns
      |> assign_new(:sidebar_toggle, fn -> false end)
      |> assign_new(:menu_toggle, fn -> false end)
      |> assign_new(:dark_mode, fn -> false end)
      |> assign_new(:notification_dropdown_open, fn -> false end)
      |> assign_new(:notifying, fn -> true end)
      |> assign_new(:user_dropdown_open, fn -> false end)

    Phoenix.Template.render(__MODULE__, "partials/partials_header", "html", assigns)
  end
  """
end
