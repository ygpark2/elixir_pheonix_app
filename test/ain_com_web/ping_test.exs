defmodule AinComWeb.PingTest do
  use AinComWeb.ConnCase

  test "GET /ping", %{conn: conn} do
    conn = get(conn, "/ping")

    assert response(conn, 200)
  end
end
