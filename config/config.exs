import Config

version = Mix.Project.config()[:version]

config :absinthe_security, AbsintheSecurity.Phase.MaxAliasesCheck, max_alias_count: 100
config :absinthe_security, AbsintheSecurity.Phase.MaxDepthCheck, max_depth_count: 100
config :absinthe_security, AbsintheSecurity.Phase.MaxDirectivesCheck, max_directive_count: 100

config :ain_com_booking, AinComBooking.Gettext, default_locale: "en"

config :ain_com_booking, AinComBooking.Repo,
  migration_primary_key: [type: :binary_id, default: {:fragment, "gen_random_uuid()"}],
  migration_timestamps: [type: :utc_datetime_usec],
  start_apps_before_migration: [:ssl]

config :ain_com_booking, AinComBookingGraphQL, token_limit: 2000

config :ain_com_booking, AinComBookingWeb.Endpoint,
  pubsub_server: AinComBooking.PubSub,
  render_errors: [view: AinComBookingWeb.Errors, accepts: ~w(html json)]

config :ain_com_booking, AinComBookingWeb.Plugs.Security, allow_unsafe_scripts: false
config :ain_com_booking, Corsica, allow_headers: :all

config :ain_com_booking, :pow,
  user: AinComBooking.Accounts.User,
  repo: AinComBooking.Repo,
  extensions: [PowEmailConfirmation, PowPersistentSession, PowResetPassword],
  # controller_callbacks: Pow.Extension.Phoenix.ControllerCallbacks
  controller_callbacks: AinComBookingWeb.PowControllerCallbacks

config :ain_com_booking,
  ecto_repos: [AinComBookingApi.Repo],
  version: version

config :esbuild,
  version: "0.16.4",
  default: [
    args: ~w(js/app.js --bundle --target=es2016 --outdir=../priv/static/assets),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :logger, backends: [:console, Sentry.LoggerBackend]

config :phoenix, :json_library, Jason

config :sentry,
  # included_environments: [:all],
  dsn: [:all],
  root_source_code_path: File.cwd!(),
  release: version

# Import environment configuration
import_config "#{Mix.env()}.exs"
