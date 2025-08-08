defmodule AinComBookingApi.Controllers.AuthController do
  use Phoenix.Controller
  use PhoenixSwagger

  import AinComBookingApi.Errors

  alias AinComBooking.Accounts
  alias AinComBookingApi.Guardian

  # POST /api/auth/signup
  swagger_path :signup do
    post("/auth/signup")
    summary("Register a new user")
    description("Registers a user with email and password")
    consumes("application/json")
    produces("application/json")

    parameter(:user, :body, Schema.ref(:SignupRequest), "User signup details")

    response(201, "User created", Schema.ref(:UserResponse))
    response(422, "Validation errors", Schema.ref(:ErrorsResponse))
  end

  def signup(conn, %{"email" => email, "password" => password}) do
    case Accounts.register_user(%{"email" => email, "password" => password}) do
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

  # POST /api/auth/login
  swagger_path :login do
    post("/auth/login")
    summary("Authenticate user")
    description("Generates a JWT access token for valid credentials")
    consumes("application/json")
    produces("application/json")

    parameter(:credentials, :body, Schema.ref(:LoginRequest), "Login credentials")

    response(200, "Authenticated", Schema.ref(:TokenResponse))
    response(401, "Invalid credentials")
  end

  def login(conn, %{"email" => email, "password" => password}) do
    case Accounts.authenticate_user(email, password) do
      {:ok, user} ->
        {:ok, token, _claims} = Guardian.encode_and_sign(user)
        json(conn, %{access_token: token})

      {:error, :unauthorized} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Invalid credentials"})
    end
  end

  # === Schema definitions for Swagger ===
  def swagger_definitions do
    %{
      SignupRequest:
        swagger_schema do
          title("SignupRequest")
          description("Parameters to register a new user")
          required([:email, :password])

          properties do
            email(:string, "User email")
            password(:string, "User password")
          end

          example(%{email: "user@example.com", password: "password123"})
        end,
      LoginRequest:
        swagger_schema do
          title("LoginRequest")
          description("Parameters to authenticate a user")
          required([:email, :password])

          properties do
            email(:string, "User email")
            password(:string, "User password")
          end

          example(%{email: "user@example.com", password: "password123"})
        end,
      UserResponse:
        swagger_schema do
          title("UserResponse")
          description("Response returned after successful registration")

          properties do
            id(:string, "User ID")
            email(:string, "User email")
          end

          example(%{id: "550e8400-e29b-41d4-a716-446655440000", email: "user@example.com"})
        end,
      TokenResponse:
        swagger_schema do
          title("TokenResponse")
          description("Response containing a JWT access token")

          properties do
            access_token(:string, "Access token")
          end

          example(%{access_token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."})
        end,
      ErrorsResponse:
        swagger_schema do
          title("ErrorsResponse")
          description("Validation error response")

          properties do
            errors(:object, "A map of field names to error messages")
          end

          example(%{errors: %{email: ["has invalid format"], password: ["too short"]}})
        end
    }
  end
end
