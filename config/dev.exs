import Config

config :ain_com_booking, AinComBookingWeb.Endpoint,
  code_reloader: true,
  debug_errors: true,
  check_origin: false,
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:default, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:default, ~w(--watch)]}
  ],
  live_reload: [
    interval: 1000,
    patterns: [
      ~r{priv/gettext/.*$},
      ~r{priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$},
      ~r{lib/ain_com_web/.*(ee?x)$}
    ],
    web_console_logger: true
  ]

config :ain_com_booking, AinComBookingWeb.Plugs.Security, allow_unsafe_scripts: true

# 콘솔 백엔드 설정은 따로
config :logger, :console,
  format: "[$level] $message\n",
  level: :info

# 일반 logger 설정
config :logger,
  handle_otp_reports: false,
  handle_sasl_reports: false

config :phoenix, :plug_init_mode, :runtime
config :phoenix, :stacktrace_depth, 20
