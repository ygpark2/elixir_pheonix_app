defmodule AinComBookingGraphQL.Middleware.RequireAuthenticatedUser do
  @moduledoc false
  @behaviour Absinthe.Middleware

  @message "Authentication required"

  @impl Absinthe.Middleware
  def call(%{context: %{current_user: current_user}} = resolution, _config) when not is_nil(current_user) do
    resolution
  end

  def call(resolution, _config) do
    Absinthe.Resolution.put_result(resolution, {:error, @message})
  end
end
