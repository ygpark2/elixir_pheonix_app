defmodule AinComBookingHealth.Router do
  use Plug.Router

  defmodule Health do
    @moduledoc false
    use Plug.Router

    plug(:match)
    plug(:dispatch)

    forward(
      "/",
      to: PlugCheckup,
      init_opts:
        PlugCheckup.Options.new(
          json_encoder: Jason,
          checks: AinComHealth.checks(),
          error_code: AinComHealth.error_code(),
          timeout: to_timeout(second: 5),
          pretty: false
        )
    )
  end

  plug(:match)
  plug(:dispatch)

  forward("/health", to: Health)

  match(_, do: conn)
end
