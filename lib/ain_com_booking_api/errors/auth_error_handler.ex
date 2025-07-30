defmodule AinComBookingApi.AuthErrorHandler do
  @moduledoc false
  @behaviour Guardian.Plug.ErrorHandler

  import Plug.Conn

  # type: :unauthenticated | :unauthorized, reason: additional info
  @impl Guardian.Plug.ErrorHandler
  def auth_error(conn, {type, _reason}, _opts) do
    # 상황에 맞는 응답을 만들어 반환합니다.
    # 여기서는 모든 인증 오류를 401 Unauthorized로 응답.
    body = Jason.encode!(%{error: to_string(type)})

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(:unauthorized, body)
  end
end
