defmodule AinComBookingApi.Controllers.Company.CompanyResourceController do
  use Phoenix.Controller
  use PhoenixSwagger

  import AinComBookingApi.Errors
  import Ecto.Query

  alias AinComBooking.Catalog.CompanyResource
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
    post("/company/resources")
    summary("Create company resource")
    description("Create a new resource for a company")
    produces("application/json")
    consumes("application/json")
    tag("Company / Resource")

    AinComBookingApi.CommonParameters.authorization()

    parameter(:resource, :body, Schema.ref(:CompanyResourceRequest), "Resource attributes")

    response(201, "Resource created", Schema.ref(:CompanyResource))
    response(422, "Invalid input")
  end

  def create(conn, params) do
    changeset = CompanyResource.changeset(%CompanyResource{}, params)

    case Repo.insert(changeset) do
      {:ok, resource} ->
        conn |> put_status(:created) |> json(resource)

      {:error, changeset} ->
        conn |> put_status(:unprocessable_entity) |> json(%{errors: Ecto.Changeset.traverse_errors(changeset, &translate_error/1)})
    end
  end

  swagger_path :update do
    patch("/company/resources/{id}")
    summary("Update a company resource")
    description("Updates resource details")
    consumes("application/json")
    produces("application/json")
    tag("Company / Resource")

    AinComBookingApi.CommonParameters.authorization()

    parameter(:id, :path, :string, "Resource ID", required: true)
    parameter(:resource, :body, Schema.ref(:CompanyResourceRequest), "Resource attributes to update")

    response(200, "Resource updated", Schema.ref(:CompanyResource))
    response(404, "Resource not found")
    response(422, "Invalid input")
  end

  def update(conn, %{"id" => id} = params) do
    case Repo.get(CompanyResource, id) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "Resource not found"})

      resource ->
        changeset = CompanyResource.changeset(resource, Map.delete(params, "id"))

        case Repo.update(changeset) do
          {:ok, updated_resource} -> json(conn, updated_resource)
          {:error, changeset} -> conn |> put_status(:unprocessable_entity) |> json(%{errors: Ecto.Changeset.traverse_errors(changeset, &translate_error/1)})
        end
    end
  end

  swagger_path :index do
    get("/company/resources")
    produces("application/json")
    tag("Company / Resource")

    AinComBookingApi.CommonParameters.authorization()
    AinComBookingApi.CommonParameters.sorting()
  end

  def index(conn, _params) do
    resources = Repo.all(CompanyResource)
    json(conn, resources)
  end

  swagger_path :delete do
    delete("/company/resources/{id}")
    summary("Delete resource")
    produces("application/json")
    tag("Company / Resource")

    AinComBookingApi.CommonParameters.authorization()

    parameter(:id, :path, :string, "CompanyResource ID", required: true)

    response(204, "CompanyResource deleted")
    response(404, "CompanyResource not found")
  end

  def remove(conn, %{"id" => id}) do
    case Repo.get(CompanyResource, id) do
      nil -> send_resp(conn, :not_found, "")
      resource -> resource |> Repo.delete!() |> then(fn _ -> send_resp(conn, :no_content, "") end)
    end
  end

  def swagger_definitions do
    %{
      CompanyResource:
        swagger_schema do
          title("CompanyResource")
          description("Represents a company resource")

          properties do
            id(:string, "Resource ID")
            name(:string)
            type(:string)
            location(:string)
            description(:string)
            company_id(:string)
            user_id(:string)
          end

          example(%{
            id: "res123",
            name: "Projector",
            type: "equipment",
            location: "Room 101",
            description: "High quality projector",
            company_id: "comp123",
            user_id: "user123"
          })
        end,
      CompanyResourceRequest:
        swagger_schema do
          title("CompanyResourceRequest")
          description("Payload for creating/updating a resource")

          properties do
            name(:string, "Resource name")
            type(:string, "Resource type")
            location(:string, "Location")
            description(:string, "Description")
            company_id(:string, "Company ID")
            user_id(:string, "User ID")
          end

          required([:name, :type, :company_id])

          example(%{
            name: "Projector",
            type: "equipment",
            location: "Room 101",
            description: "High quality projector",
            company_id: "comp123",
            user_id: "user123"
          })
        end
    }
  end
end
