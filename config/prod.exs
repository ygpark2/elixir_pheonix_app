import Config

config :ain_com, AinComWeb.Endpoint,
  cache_static_manifest: "priv/static/cache_manifest.json",
  debug_errors: false

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  level: :info,
  metadata: ~w(request_id graphql_operation_name)a
