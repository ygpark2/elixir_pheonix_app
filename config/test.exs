import Config

if Code.ensure_loaded?(Dotenv) do
  Dotenv.load(".env.test")
end

# This config is to output keys instead of translated message in test
config :ain_com_booking, AinComBooking.Gettext, priv: "priv/null", interpolation: AinComBooking.GettextInterpolation

config :ain_com_booking, AinComBooking.Repo,
  database: Path.expand("../priv/repo/test.sqlite3", __DIR__),
  migration_primary_key: [type: :binary_id, default: nil],
  migration_foreign_key: [type: :binary_id],
  migration_timestamps: [type: :utc_datetime_usec],
  pool_size: 1,
  busy_timeout: 5_000,
  journal_mode: :wal,
  pool: Ecto.Adapters.SQL.Sandbox,
  adapter: Ecto.Adapters.SQLite3

config :ain_com_booking, AinComBookingWeb.Endpoint,
  secret_key_base: String.duplicate("a", 64),
  session_key: "_ain_com_booking_session",
  session_signing_salt: "test_signing_salt"

config :ain_com_booking, AinComBookingWeb.Endpoint, server: false
config :ain_com_booking, Corsica, origins: :all
config :ain_com_booking, :telemetry_ui_enabled, false

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

config :logger, level: :warning
