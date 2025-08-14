defmodule AinCom.Mixfile do
  use Mix.Project

  def project do
    [
      app: :ain_com_booking,
      version: "0.0.1",
      erlang: "~> 27.3",
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers() ++ [:phoenix_swagger],
      test_paths: ["test"],
      test_pattern: "**/*_test.exs",
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :test, "coveralls.detail": :test, "coveralls.post": :test, "coveralls.html": :test],
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      dialyzer: dialyzer(),
      releases: releases()
    ]
  end

  def application do
    [
      mod: {AinComBooking.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp aliases do
    [
      "assets.deploy": [
        "tailwind default --minify",
        "esbuild default --minify",
        "phx.digest"
      ],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end

  defp deps do
    [
      {:bcrypt_elixir, "~> 3.0"},
      # Assets bundling
      {:esbuild, "~> 0.9", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.3", runtime: Mix.env() == :dev},
      {:dotenv, "~> 3.1", only: [:dev, :test]},

      # HTTP Client
      {:hackney, "~> 1.23"},

      # HTTP server
      {:plug_cowboy, "~> 2.7"},
      {:plug_canonical_host, "~> 2.0"},
      {:corsica, "~> 2.1"},

      # Phoenix
      {:phoenix, "~> 1.7"},
      {:phoenix_html, "~> 4.2"},
      {:phoenix_live_view, "~> 1.1.2"},
      {:phoenix_ecto, "~> 4.6.3"},
      {:phoenix_live_reload, "~> 1.5", only: :dev},
      {:jason, "~> 1.4"},

      # Swagger 문서
      {:phoenix_swagger, "~> 0.8"},
      {:ex_json_schema, "~> 0.7"},

      # Dashboard
      # {:fluxon, "~> 1.1.0", repo: :fluxon},
      {:phoenix_live_dashboard, "~> 0.7"},

      # GraphQL
      {:absinthe, "~> 1.7"},
      {:absinthe_security, "~> 0.1"},
      {:absinthe_plug, "~> 1.5"},
      {:dataloader, "~> 2.0"},
      {:absinthe_error_payload, "~> 1.2"},

      # Scheduller
      # 백그라운드 작업
      {:oban, "~> 2.19"},

      # Email
      {:swoosh, "~> 1.19"},
      # SMTP가 아닌 경우 필요
      {:finch, "~> 0.20"},

      # Auth
      {:guardian, "~> 2.3"},

      # Database
      {:ecto_sql, "~> 3.12"},
      {:postgrex, "~> 0.20"},
      {:ecto_psql_extras, "~> 0.6"},

      # Database check
      {:excellent_migrations, "~> 0.1", only: [:dev, :test], runtime: false},

      # Translations
      {:gettext, "~> 0.26"},

      # Errors
      {:sentry, "~> 10.9"},

      # Monitoring
      {:new_relic_agent, "~> 1.34"},
      {:new_relic_absinthe, "~> 0.0"},

      # Telemetry
      {:telemetry_ui, "~> 5.0"},

      # Linting
      {:credo, "~> 1.7", only: [:dev, :test], override: true},
      {:credo_envvar, "~> 0.1", only: [:dev, :test], runtime: false},
      {:credo_naming, "~> 2.1", only: [:dev, :test], runtime: false},
      {:styler, "~> 1.4", only: [:dev, :test], runtime: false},

      # Security check
      {:sobelow, "~> 0.13", only: [:dev, :test], runtime: true},
      {:mix_audit, "~> 2.1", only: [:dev, :test], runtime: false},

      # Health
      {:plug_checkup, "~> 0.6"},

      # Test factories
      {:ex_machina, "~> 2.8", only: :test},
      {:faker, "~> 0.18", only: :test},

      # Test coverage
      {:excoveralls, "~> 0.18", only: :test},

      # Dialyzer
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end

  defp dialyzer do
    [
      plt_file: {:no_warn, "priv/plts/ain_com_booking.plt"},
      plt_add_apps: [:mix, :ex_unit]
    ]
  end

  defp releases do
    [
      ain_com_booking: [
        version: {:from_app, :ain_com_booking},
        # applications: [ain_com_booking: :permanent],
        include_executables_for: [:unix],
        steps: [:assemble, :tar]
      ]
    ]
  end
end
