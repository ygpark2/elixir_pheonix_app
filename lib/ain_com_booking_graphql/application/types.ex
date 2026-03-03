defmodule AinComBookingGraphQL.Application.Types do
  @moduledoc false
  use Absinthe.Schema.Notation

  alias AinComBookingGraphQL.Middleware

  object :application do
    @desc "The application version"
    field(:version, :string)
  end

  object :user do
    field(:id, non_null(:id))
    field(:email, non_null(:string))
    field(:name, non_null(:string))
    field(:phone, non_null(:string))
    field(:address, non_null(:string))
    field(:confirmed_at, :naive_datetime)
  end

  object :application_queries do
    @desc "A list of application information"
    field :application, :application do
      resolve(fn _, _, _ -> {:ok, %{version: version()}} end)
    end

    @desc "The currently authenticated user"
    field :me, :user do
      middleware(Middleware.RequireAuthenticatedUser)
      resolve(fn _, _, %{context: %{current_user: current_user}} -> {:ok, current_user} end)
    end
  end

  defp version, do: Application.get_env(:ain_com_booking, :version)
end
