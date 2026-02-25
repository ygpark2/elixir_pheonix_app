defmodule AinComBookingWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common datastructures and query the data layer.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate

  alias AinComBooking.Repo
  alias AinComBookingWeb.Endpoint
  alias Ecto.Adapters.SQL.Sandbox
  alias Phoenix.ConnTest

  using do
    quote do
      # Import conveniences for testing with connections
      use AinComBookingWeb, :verified_routes

      import AinComBookingWeb.ConnCase
      import AinComBookingWeb.Router.Helpers
      import Phoenix.ConnTest
      import Plug.Conn

      # The default endpoint for testing
      @endpoint Endpoint
    end
  end

  setup tags do
    :ok = Sandbox.checkout(Repo)

    if !tags[:async] do
      Sandbox.mode(Repo, {:shared, self()})
    end

    secret_key_base =
      :ain_com_booking
      |> Application.fetch_env!(Endpoint)
      |> Keyword.fetch!(:secret_key_base)

    {:ok, conn: %{ConnTest.build_conn() | host: host(), secret_key_base: secret_key_base}}
  end

  defp host, do: Application.get_env(:ain_com_booking, :canonical_host)

  @doc """
  Setup helper that registers and logs in users.

      setup :register_and_log_in_user

  It stores an updated connection and a registered user in the
  test context.
  """
  def register_and_log_in_user(%{conn: conn}) do
    user = AinComBooking.AccountsFixtures.user_fixture()
    %{conn: log_in_user(conn, user), user: user}
  end

  @doc """
  Logs the given `user` into the `conn`.

  It returns an updated `conn`.
  """
  def log_in_user(conn, user) do
    token = AinComBooking.Accounts.generate_user_session_token(user)
    live_socket_id = "users_sessions:#{Base.url_encode64(token)}"
    session_opts = Plug.Session.init(AinComBookingWeb.Session.config())

    conn
    |> Plug.Session.call(session_opts)
    |> Plug.Conn.fetch_session()
    |> Plug.Conn.put_session(:user_token, token)
    |> Plug.Conn.put_session("user_token", token)
    |> Plug.Conn.put_session(:live_socket_id, live_socket_id)
    |> Plug.Conn.put_session("live_socket_id", live_socket_id)
    |> Plug.Conn.send_resp(200, "")
    |> ConnTest.recycle()
  end
end
