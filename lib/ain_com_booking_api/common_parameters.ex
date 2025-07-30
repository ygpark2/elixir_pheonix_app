defmodule AinComBookingApi.CommonParameters do
  @moduledoc "Common parameter declarations for phoenix swagger"
  use PhoenixSwagger

  import PhoenixSwagger.Path

  alias PhoenixSwagger.Path.PathObject

  def authorization(%PathObject{} = path) do
    path
    |> parameter("Authorization", :header, :string, "JWT access token", required: true)
    |> parameter("device_token", :header, :string, "Device Unique Token", required: true)
  end

  def sorting(%PathObject{} = path) do
    path
    |> parameter(:sort_by, :query, :string, "The property to sort by")
    |> parameter(:sort_direction, :query, :string, "The sort direction", enum: [:asc, :desc], default: :asc)
  end

  def swagger_definitions do
    %{
      securitySchemes: %{
        jwtAuth: %{
          type: "apiKey",
          in: "header",
          name: "Authorization",
          description: "JWT access token"
        },
        deviceTokenAuth: %{
          type: "apiKey",
          in: "header",
          name: "device_token",
          description: "Device Unique Token"
        }
      }
    }
  end
end
