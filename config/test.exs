import Config

if Code.ensure_loaded?(Dotenv) do
  Dotenv.load(".env.test")
end

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

defmodule TestEnvironment do
  @moduledoc false
  @database_name_suffix "_test"

  def get_database_url do
    url = System.get_env("DATABASE_URL")

    if is_nil(url) || String.ends_with?(url, @database_name_suffix) do
      url
    else
      raise "Expected database URL to end with '#{@database_name_suffix}', got: #{url}"
    end
  end
end

# This config is to output keys instead of translated message in test
config :ain_com_booking, AinComBooking.Gettext, priv: "priv/null", interpolation: AinComBooking.GettextInterpolation

config :ain_com_booking, AinComBooking.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  url: TestEnvironment.get_database_url()

config :ain_com_booking, AinComBookingWeb.Endpoint, server: false

config :logger, level: :warning
