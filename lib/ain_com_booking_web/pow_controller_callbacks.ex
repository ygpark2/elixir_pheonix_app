defmodule AinComWeb.PowControllerCallbacks do
  @moduledoc """
  Assigns an existing guest Player to the newly created User record
  """

  use Pow.Extension.Phoenix.ControllerCallbacks.Base

  def before_respond(Pow.Phoenix.RegistrationController, :create, {:ok, user, conn}, _config) do
    # send email
    #

    {:ok, user, conn}
  end
end
