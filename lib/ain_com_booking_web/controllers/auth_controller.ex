defmodule AinComBookingWeb.AuthController do
  use AinComBookingWeb, :controller

  alias AinComBookingApi.Accounts.Auth
  alias AinComBookingApi.Guardian

  def signup(conn, %{"email" => email, "password" => password}) do
    case Auth.register_user(%{"email" => email, "password" => password}) do
      {:ok, user} ->
        conn
        |> put_status(:created)
        |> json(%{id: user.id, email: user.email})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: Ecto.Changeset.traverse_errors(changeset, &translate_error/1)})
    end
  end

  def login(conn, %{"email" => email, "password" => password}) do
    case Auth.authenticate_user(email, password) do
      {:ok, user} ->
        {:ok, token, _claims} = Guardian.encode_and_sign(user)
        json(conn, %{access_token: token})

      {:error, :unauthorized} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Invalid credentials"})
    end
  end
end
