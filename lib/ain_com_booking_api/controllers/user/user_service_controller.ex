defmodule AinComBookingApi.Controllers.User.UserServiceController do
  use Phoenix.Controller
  use PhoenixSwagger

  import AinComBookingApi.Errors

  alias AinComBooking.Catalog.UserService
  alias AinComBooking.Repo

  def swagger_paths do
    [:create, :update, :index, :delete]
  end

  swagger_path :create do
    post("/user/services")
    summary("Create user service")
    description("Create a new company service")
    produces("application/json")
    consumes("application/json")
    tag("User")

    AinComBookingApi.CommonParameters.authorization()

    parameter(:service, :body, Schema.ref(:UserServiceRequest), "UserService attributes")

    response(201, "UserService created", Schema.ref(:UserService))
    response(422, "Invalid input")
  end

  def create(conn, params) do
    changeset = UserService.changeset(%UserService{}, params)

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
    patch("/user/services/{id}")
    summary("Update service")
    description("Updates an existing service")
    consumes("application/json")
    produces("application/json")
    tag("User")

    AinComBookingApi.CommonParameters.authorization()

    parameter(:id, :path, :string, "Service ID", required: true)
    parameter(:service, :body, Schema.ref(:UserServiceRequest), "UserService attributes")

    response(200, "UserService updated", Schema.ref(:UserService))
    response(404, "UserService not found")
    response(422, "Invalid input")
  end

  def update(conn, %{"id" => id} = params) do
    case Repo.get(UserService, id) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "UserService not found"})

      service ->
        changeset = UserService.changeset(service, Map.delete(params, "id"))

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
    get("/user/services")
    summary("List services")
    produces("application/json")
    tag("User")

    AinComBookingApi.CommonParameters.authorization()
  end

  def index(conn, _params) do
    services = Repo.all(UserService)
    json(conn, services)
  end

  swagger_path :delete do
    delete("/user/services/{id}")
    summary("Delete service")
    produces("application/json")
    tag("User")

    AinComBookingApi.CommonParameters.authorization()

    parameter(:id, :path, :string, "Service ID", required: true)

    response(204, "Service deleted")
    response(404, "Service not found")
  end

  def remove(conn, %{"id" => id}) do
    case Repo.get(UserService, id) do
      nil ->
        send_resp(conn, :not_found, "")

      service ->
        Repo.delete!(service)
        send_resp(conn, :no_content, "")
    end
  end


  def swagger_definitions do
    %{
      UserService:
        swagger_schema do
          title("UserService")
          description("A user service")

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
      UserServiceRequest:
        swagger_schema do
          title("UserServiceRequest")
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
