alias Ecto.Adapters.SQLite3

# NOTE: When using Elixir 1.12+, we could ditch the next line and use `mix test --warnings-as-errors` instead
Code.put_compiler_option(:warnings_as_errors, true)

{:ok, _} = Application.ensure_all_started(:ex_machina)

Code.require_file("support/data_case.ex", __DIR__)
Code.require_file("support/conn_case.ex", __DIR__)
Code.require_file("support/channel_case.ex", __DIR__)
Code.require_file("support/factory.ex", __DIR__)
Code.require_file("support/gettext_interpolation.ex", __DIR__)

repo_adapter = Application.get_env(:ain_com_booking, AinComBooking.Repo)[:adapter]
max_cases = if repo_adapter == SQLite3, do: 1, else: 32

if repo_adapter == SQLite3 do
  db_path = Application.get_env(:ain_com_booking, AinComBooking.Repo)[:database]

  if is_binary(db_path) and File.exists?(db_path) do
    File.rm!(db_path)
  end

  for suffix <- ["-shm", "-wal"] do
    path = db_path <> suffix

    if File.exists?(path) do
      File.rm!(path)
    end
  end
end

ExUnit.start(max_cases: max_cases)

Ecto.Adapters.SQL.Sandbox.mode(AinComBooking.Repo, :manual)
