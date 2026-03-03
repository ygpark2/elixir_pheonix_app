defmodule AinComBookingGraphQL.Plugs.Context do
  @moduledoc false
  @behaviour Plug

  import Plug.Conn

  alias AinComBookingApi.Guardian
  alias AinComBookingWeb.UserAuth

  def init(opts), do: opts

  def call(conn, _) do
    conn =
      conn
      |> fetch_session()
      |> UserAuth.fetch_current_user([])

    put_private(conn, :absinthe, build_absinthe_context(conn))
  end

  defp build_absinthe_context(conn) do
    absinthe = Map.get(conn.private, :absinthe, %{})
    context = absinthe |> Map.get(:context, %{}) |> Map.merge(build_context(conn))

    Map.put(absinthe, :context, context)
  end

  defp build_context(conn) do
    conn
    |> current_user()
    |> then(&%{current_user: &1})
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp current_user(conn) do
    conn.assigns[:current_user] || bearer_user(conn)
  end

  defp bearer_user(conn) do
    conn
    |> bearer_token()
    |> case do
      nil -> nil
      token -> user_from_token(token)
    end
  end

  defp bearer_token(conn) do
    conn
    |> get_req_header("authorization")
    |> List.first()
    |> parse_bearer_token()
  end

  defp parse_bearer_token("Bearer " <> token) when byte_size(token) > 0, do: token
  defp parse_bearer_token(_), do: nil

  defp user_from_token(token) do
    with {:ok, claims} <- Guardian.decode_and_verify(token),
         {:ok, user} <- Guardian.resource_from_claims(claims) do
      user
    else
      _ -> nil
    end
  end
end
