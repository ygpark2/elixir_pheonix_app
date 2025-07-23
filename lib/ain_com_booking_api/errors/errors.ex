defmodule AinComBookingApi.Errors do
  @moduledoc false
  alias Ecto.Changeset

  @doc """
  Generates a human-readable block containing all errors in a changeset. Errors
  are then localized using translations in the `ecto` domain.

  For example, you could have an `errors.po` file in the french locale:

  ```
  msgid ""
  msgstr ""
  "Language: fr"

  msgid "can't be blank"
  msgstr "ne peut être vide"
  ```
  """

  def translate_error({message, options}) do
    if options[:count] do
      Gettext.dngettext(AinComBooking.Gettext, "errors", message, message, options[:count], options)
    else
      Gettext.dgettext(AinComBooking.Gettext, "errors", message, options)
    end
  end
end
