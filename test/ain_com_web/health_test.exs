defmodule AinComWeb.HealthTest do
  use AinComWeb.ConnCase

  test "GET /health", %{conn: conn} do
    conn = get(conn, "/health")

    assert response(conn, 200)
  end
end
