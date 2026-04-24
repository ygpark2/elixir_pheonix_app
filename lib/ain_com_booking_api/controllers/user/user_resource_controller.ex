defmodule AinComBookingApi.Controllers.User.UserResourceController do
  use Phoenix.Controller
  use PhoenixSwagger

  import AinComBookingApi.Errors
  import Ecto.Query

  alias AinComBooking.Catalog.UserResource
  alias AinComBooking.Repo

  def swagger_paths do
    [
      :create,
      :update,
      :index,
      :delete
    ]
  end

  swagger_path :create do
    post("/user/resources")
    summary("Create user resource")
    description("Create a new resource for a user")
    produces("application/json")
    consumes("application/json")
    tag("User")

    AinComBookingApi.CommonParameters.authorization()

    parameter(:resource, :body, Schema.ref(:UserResourceRequest), "Resource attributes")

    response(201, "UserResource created", Schema.ref(:UserResource))
    response(422, "Invalid input")
  end

  def create(conn, params) do
    changeset = UserResource.changeset(%UserResource{}, params)

    case Repo.insert(changeset) do
      {:ok, resource} ->
        conn |> put_status(:created) |> json(resource)

      {:error, changeset} ->
        conn |> put_status(:unprocessable_entity) |> json(%{errors: Ecto.Changeset.traverse_errors(changeset, &translate_error/1)})
    end
  end

  swagger_path :update do
    patch("/user/resources/{id}")
    summary("Update a user resource")
    description("Updates resource details")
    consumes("application/json")
    produces("application/json")
    tag("User")

    AinComBookingApi.CommonParameters.authorization()

    parameter(:id, :path, :string, "UserResource ID", required: true)
    parameter(:resource, :body, Schema.ref(:UserResourceRequest), "Resource attributes to update")

    response(200, "UserResource updated", Schema.ref(:UserResource))
    response(404, "UserResource not found")
    response(422, "Invalid input")
  end

  def update(conn, %{"id" => id} = params) do
    case Repo.get(UserResource, id) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "UserResource not found"})

      resource ->
        changeset = UserResource.changeset(resource, Map.delete(params, "id"))

        case Repo.update(changeset) do
          {:ok, updated_resource} -> json(conn, updated_resource)
          {:error, changeset} -> conn |> put_status(:unprocessable_entity) |> json(%{errors: Ecto.Changeset.traverse_errors(changeset, &translate_error/1)})
        end
    end
  end

  swagger_path :index do
    get("/user/resources")
    produces("application/json")
    tag("User")

    AinComBookingApi.CommonParameters.authorization()
    AinComBookingApi.CommonParameters.sorting()
  end

  def index(conn, _params) do
    resources = Repo.all(UserResource)
    json(conn, resources)
  end

  swagger_path :delete do
    delete("/user/resources/{id}")
    summary("Delete user resource")
    produces("application/json")
    tag("User")

    AinComBookingApi.CommonParameters.authorization()

    parameter(:id, :path, :string, "Resource ID", required: true)

    response(204, "UserResource deleted")
    response(404, "UserResource not found")
  end

  def remove(conn, %{"id" => id}) do
    case Repo.get(UserResource, id) do
      nil -> send_resp(conn, :not_found, "")
      resource -> resource |> Repo.delete!() |> then(fn _ -> send_resp(conn, :no_content, "") end)
    end
  end


  def swagger_definitions do
    %{
      UserResource:
        swagger_schema do
          title("UserResource")
          description("Represents a user resource")

          properties do
            id(:string, "Resource ID")
            name(:string)
            type(:string)
            location(:string)
            description(:string)
            price(:number)
            currency(:string)
            user_id(:string)
          end

          example(%{
            id: "res123",
            name: "Projector",
            type: "equipment",
            location: "Room 101",
            description: "High quality projector",
            price: 10_000,
            currency: "KRW",
            user_id: "user123"
          })
        end,
      UserResourceRequest:
        swagger_schema do
          title("UserResourceRequest")
          description("Payload for creating/updating a resource")

          properties do
            name(:string, "Resource name")
            type(:string, "Resource type")
            location(:string, "Location")
            description(:string, "Description")
            price(:number, "Bookable resource price")
            currency(:string, "Currency")
            user_id(:string, "User ID")
          end

          required([:name, :type, :price, :currency, :user_id])

          example(%{
            name: "Projector",
            type: "equipment",
            location: "Room 101",
            description: "High quality projector",
            price: 10_000,
            currency: "KRW",
            user_id: "user123"
          })
        end
    }
  end
end
