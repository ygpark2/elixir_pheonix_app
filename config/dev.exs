import Config

config :ain_com_booking, AinComBookingWeb.Endpoint,
  code_reloader: true,
  debug_errors: true,
  check_origin: false,
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:default, ~w(--sourcemap=inline --watch)]}
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

config :logger, :console, format: "[$level] $message\n"

config :phoenix, :plug_init_mode, :runtime
config :phoenix, :stacktrace_depth, 20
