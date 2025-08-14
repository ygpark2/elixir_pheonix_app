import Config

version = Mix.Project.config()[:version]

config :absinthe_security, AbsintheSecurity.Phase.MaxAliasesCheck, max_alias_count: 100
config :absinthe_security, AbsintheSecurity.Phase.MaxDepthCheck, max_depth_count: 100
config :absinthe_security, AbsintheSecurity.Phase.MaxDirectivesCheck, max_directive_count: 100

config :ain_com_booking, AinComBooking.Gettext, default_locale: "en"
config :ain_com_booking, AinComBooking.Mailer, adapter: Swoosh.Adapters.Local

config :ain_com_booking, AinComBooking.Repo,
  migration_primary_key: [type: :binary_id, default: {:fragment, "gen_random_uuid()"}],
  migration_foreign_key: [type: :binary_id],
  migration_timestamps: [type: :utc_datetime_usec],
  start_apps_before_migration: [:ssl]

config :ain_com_booking, AinComBookingApi.Guardian,
  issuer: "ain_com_booking",
  secret_key: "LChh25xnTb9CFOZKW90mZ+MGDZKqXFMzbRlGxeaEAqOQlRbmQqDDHlIdyLj1pf3b"

config :ain_com_booking, AinComBookingGraphQL, token_limit: 2000
config :ain_com_booking, AinComBookingWeb.Endpoint, live_view: [signing_salt: "DtRf6n528OmwGAAyY876p4tzT1pH2oyQ"]

config :ain_com_booking, AinComBookingWeb.Endpoint,
  pubsub_server: AinComBooking.PubSub,
  render_errors: [view: AinComBookingWeb.Errors, accepts: ~w(html json)]

# 선택 사항
config :ain_com_booking, AinComBookingWeb.Plugs.Security, allow_unsafe_scripts: false
config :ain_com_booking, Corsica, allow_headers: :all

config :ain_com_booking, :phoenix_swagger,
  swagger_files: %{
    "priv/static/swagger.json" => [
      router: AinComBookingWeb.Router,
      endpoint: AinComBookingWeb.Endpoint
    ]
  }

config :ain_com_booking,
  ecto_repos: [AinComBooking.Repo],
  version: version

config :esbuild,
  version: "0.16.4",
  default: [
    args: ~w(js/app.jsx --bundle --target=es2017 --outdir=../priv/static/assets
      --loader:.js=jsx --loader:.jsx=jsx --jsx=automatic),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :tailwind,
  version: "4.0.9",
  default: [
    args: ~w(--config=tailwind.config.js --input=css/app.css --output=../priv/static/assets/app.css),
    cd: Path.expand("../assets", __DIR__)
  ]

config :logger, backends: [:console, Sentry.LoggerBackend]

config :phoenix, :json_library, Jason

# 사용할 JSON 인코딩 라이브러리 설정
config :phoenix_swagger, json_library: Jason

config :sentry,
  dsn: if(Mix.env() == :prod, do: System.get_env("SENTRY_DSN")),
  enable_source_code_context: true,
  root_source_code_path: File.cwd!(),
  # [:prod, :dev],
  # included_environments: [:prod],
  # dsn: get_env("SENTRY_DSN", :uri),
  # environment_name: Mix.env(),
  # Swoosh API 서버 뷰 사용
  release: version

config :swoosh, :api_client, false

# Import environment configuration
import_config "#{Mix.env()}.exs"
