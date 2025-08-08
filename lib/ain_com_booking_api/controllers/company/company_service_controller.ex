defmodule AinComBookingApi.Controllers.Company.CompanyServiceController do
  use Phoenix.Controller
  use PhoenixSwagger

  import AinComBookingApi.Errors

  alias AinComBooking.Catalog.CompanyService
  alias AinComBooking.Repo

  def swagger_paths do
    [:create, :update, :index, :delete]
  end

  swagger_path :create do
    post("/company/services")
    summary("Create service")
    description("Create a new company service")
    produces("application/json")
    consumes("application/json")
    tag("Company / Service")

    AinComBookingApi.CommonParameters.authorization()

    parameter(:service, :body, Schema.ref(:CompanyServiceRequest), "Service attributes")

    response(201, "Service created", Schema.ref(:CompanyService))
    response(422, "Invalid input")
  end

  def create(conn, params) do
    changeset = CompanyService.changeset(%CompanyService{}, params)

    case Repo.insert(changeset) do
      {:ok, service} ->
        conn |> put_status(:created) |> json(service)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: Ecto.Changeset.traverse_errors(changeset, &translate_error/1)})
    end
  end

  swagger_path :update do
    patch("/company/services/{id}")
    summary("Update service")
    description("Updates an existing service")
    consumes("application/json")
    produces("application/json")
    tag("Company / Service")

    AinComBookingApi.CommonParameters.authorization()

    parameter(:id, :path, :string, "Service ID", required: true)
    parameter(:service, :body, Schema.ref(:CompanyServiceRequest), "Service attributes")

    response(200, "Service updated", Schema.ref(:CompanyService))
    response(404, "Service not found")
    response(422, "Invalid input")
  end

  def update(conn, %{"id" => id} = params) do
    case Repo.get(CompanyService, id) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "Service not found"})

      service ->
        changeset = CompanyService.changeset(service, Map.delete(params, "id"))

        case Repo.update(changeset) do
          {:ok, updated_service} ->
            json(conn, updated_service)

          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{errors: Ecto.Changeset.traverse_errors(changeset, &translate_error/1)})
        end
    end
  end

  swagger_path :index do
    get("/company/services")
    summary("List company services")
    produces("application/json")
    tag("Company / Service")

    AinComBookingApi.CommonParameters.authorization()
  end

  def index(conn, _params) do
    services = Repo.all(CompanyService)
    json(conn, services)
  end

  swagger_path :delete do
    delete("/company/services/{id}")
    summary("Delete service")
    produces("application/json")
    tag("Company / Service")

    AinComBookingApi.CommonParameters.authorization()

    parameter(:id, :path, :string, "Service ID", required: true)

    response(204, "Service deleted")
    response(404, "Service not found")
  end

  def remove(conn, %{"id" => id}) do
    case Repo.get(CompanyService, id) do
      nil ->
        send_resp(conn, :not_found, "")

      service ->
        Repo.delete!(service)
        send_resp(conn, :no_content, "")
    end
  end

  def swagger_definitions do
    %{
      CompanyService:
        swagger_schema do
          title("CompanyService")
          description("A company service")

          properties do
            id(:string)
            name(:string)
            description_text(:string)
            duration(:integer)
            price(:number)
            currency(:string)
            is_active(:boolean)
            is_public(:boolean)
          end

          example(%{
            id: "xyz789",
            name: "Consulting",
            description_text: "30-min consultation",
            duration: 30,
            price: 49.99,
            currency: "USD",
            is_active: true,
            is_public: true
          })
        end,
      CompanyServiceRequest:
        swagger_schema do
          title("CompanyServiceRequest")
          description("Attributes for creating/updating a service")

          properties do
            name(:string, "Service name")
            description_text(:string, "Description")
            duration(:integer, "Duration in minutes")
            price(:number, "Price")
            currency(:string, "Currency")
            is_active(:boolean)
            is_public(:boolean)
          end

          example(%{
            name: "Consulting",
            description_text: "30-min consultation",
            duration: 30,
            price: 49.99,
            currency: "USD",
            is_active: true,
            is_public: true
          })
        end
    }
  end
end
