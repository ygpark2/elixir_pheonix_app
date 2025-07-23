defmodule AinComBooking.Gettext do
  @moduledoc """
  This module manages everything related to the translations used in the
  application.
  """

  use Gettext.Backend, otp_app: :ain_com_booking
  use Gettext, backend: AinCom.Gettext
end
