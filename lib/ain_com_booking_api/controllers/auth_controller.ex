defmodule AinComBookingApi.Controllers.AuthController do
  use Phoenix.Controller
  use PhoenixSwagger

  import AinComBookingApi.Errors

  alias AinComBooking.Accounts
  alias AinComBookingApi.Guardian
  alias AinComBookingApi.Devices

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
    description("Generates a JWT access token and device token for valid credentials")
    consumes("application/json")
    produces("application/json")

    parameter(:credentials, :body, Schema.ref(:LoginRequest), "Login credentials")

    response(200, "Authenticated", Schema.ref(:TokenResponse))
    response(201, "Authenticated (new device)", Schema.ref(:TokenResponse))
    response(401, "Invalid credentials")
  end

  def login(conn, %{"email" => email, "password" => password} = params) do
    with {:ok, user} <- Accounts.authenticate_user(email, password),
         {:ok, access_token, _claims} <- Guardian.encode_and_sign(user) do
      fingerprint = Map.get(params, "fingerprint") || default_fingerprint(conn)

      device_info = %{
        name: Map.get(params, "device_name", "web"),
        os: Map.get(params, "os", "browser"),
        version: Map.get(params, "version"),
        user_agent: get_req_header(conn, "user-agent") |> List.first(),
        ip: get_req_header(conn, "x-forwarded-for") |> List.first()
      }

      case Devices.create_or_get_device(user, fingerprint, device_info) do
        {:created, raw, device} ->
          conn
          |> put_status(:created)
          |> json(%{
            access_token: access_token,
            device_token: raw,
            expires_in: 3600,
            device_expires_at: device.expires_at
          })

        {:reused, _nil, device} ->
          resp =
            case Devices.rotate_if_expiring(device, 7) do
              {:ok, new_raw, new_dev} ->
                %{device_token: new_raw, device_expires_at: new_dev.expires_at}

              {:skip, dev} ->
                %{device_token: nil, device_expires_at: dev.expires_at}
            end

          json(conn, Map.merge(%{access_token: access_token, expires_in: 3600}, resp))
      end
    else
      _ ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Invalid credentials"})
    end
  end

  defp default_fingerprint(conn) do
    ua = get_req_header(conn, "user-agent") |> List.first() || "unknown"
    ip = get_req_header(conn, "x-forwarded-for") |> List.first() || "ip"
    :crypto.hash(:sha256, ua <> "|" <> ip) |> Base.encode16(case: :lower)
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
            fingerprint(:string, "Device fingerprint", required: false)
            device_name(:string, "Device name", required: false)
            os(:string, "Operating system", required: false)
            version(:string, "Device version", required: false)
          end

          example(%{
            email: "user@example.com",
            password: "password123",
            fingerprint: "abcdef123456"
          })
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
          description("Response containing tokens")

          properties do
            access_token(:string, "Access token")
            device_token(:string, "Device token", required: false)
            expires_in(:integer, "Access token TTL in seconds")
            device_expires_at(:string, "ISO8601 expiry of device token")
          end

          example(%{
            access_token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
            device_token: "86b5b3e2-34c9-43ab-9940-19c0ad19f4b2",
            expires_in: 3600,
            device_expires_at: "2025-08-08T00:00:00Z"
          })
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
