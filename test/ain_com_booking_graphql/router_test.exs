defmodule AinComBookingGraphQL.RouterTest do
  use AinComBookingWeb.ConnCase, async: true

  import AinComBooking.AccountsFixtures

  alias AinComBookingApi.Guardian

  describe "POST /graphql me" do
    test "returns the current user for a session-authenticated request", %{conn: conn} do
      user = user_fixture()

      response =
        conn
        |> log_in_user(user)
        |> execute_query(me_query())

      assert %{
               "data" => %{
                 "me" => %{
                   "id" => user_id,
                   "email" => email,
                   "name" => name
                 }
               }
             } = response

      assert user_id == user.id
      assert email == user.email
      assert name == user.name
    end

    test "returns the current user for a bearer-authenticated request", %{conn: conn} do
      user = user_fixture()
      {:ok, token, _claims} = Guardian.encode_and_sign(user)

      response =
        conn
        |> put_req_header("authorization", "Bearer " <> token)
        |> execute_query(me_query())

      assert get_in(response, ["data", "me", "id"]) == user.id
    end

    test "returns an authentication error when no user is present", %{conn: conn} do
      response = execute_query(conn, me_query())

      assert response["data"]["me"] == nil
      assert [%{"message" => "Authentication required"}] = response["errors"]
    end
  end

  defp execute_query(conn, query) do
    conn
    |> post("/graphql", query: query)
    |> response(200)
    |> Phoenix.json_library().decode!()
  end

  defp me_query do
    """
    {
      me {
        id
        email
        name
      }
    }
    """
  end
end
