defmodule AinComBookingGraphQL.Plugs.ContextTest do
  use AinComBookingWeb.ConnCase, async: true

  import AinComBooking.AccountsFixtures

  alias AinComBookingApi.Guardian
  alias AinComBookingGraphQL.Plugs.Context
  alias AinComBookingWeb.Session

  describe "call/2" do
    test "loads current_user from the browser session", %{conn: conn} do
      user = user_fixture()

      conn =
        conn
        |> log_in_user(user)
        |> Session.call([])
        |> Context.call([])

      assert conn.private.absinthe.context.current_user.id == user.id
    end

    test "loads current_user from a bearer token when no session exists", %{conn: conn} do
      user = user_fixture()
      {:ok, token, _claims} = Guardian.encode_and_sign(user)

      conn =
        conn
        |> Session.call([])
        |> put_req_header("authorization", "Bearer " <> token)
        |> Context.call([])

      assert conn.private.absinthe.context.current_user.id == user.id
    end

    test "ignores invalid bearer tokens", %{conn: conn} do
      conn =
        conn
        |> Session.call([])
        |> put_req_header("authorization", "Bearer invalid-token")
        |> Context.call([])

      assert conn.private.absinthe.context == %{}
    end
  end
end
