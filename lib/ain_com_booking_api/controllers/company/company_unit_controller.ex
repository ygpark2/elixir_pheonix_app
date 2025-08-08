defmodule AinComBookingApi.Controllers.Company.CompanyUnitController do
  use Phoenix.Controller
  use PhoenixSwagger

  import AinComBookingApi.Errors
  import Ecto.Query

  alias AinComBooking.Catalog.Unit
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
    post("/units")
    summary("Create unit")
    description("Create a new unit for a company")
    produces("application/json")
    consumes("application/json")
    tag("Company / Unit")

    AinComBookingApi.CommonParameters.authorization()

    parameter(:unit, :body, Schema.ref(:UnitRequest), "Unit attributes")

    response(201, "Unit created", Schema.ref(:Unit))
    response(422, "Invalid input")
  end

  def create(conn, params) do
    changeset = Unit.changeset(%Unit{}, params)

    case Repo.insert(changeset) do
      {:ok, unit} ->
        conn
        |> put_status(:created)
        |> json(unit)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: Ecto.Changeset.traverse_errors(changeset, &translate_error/1)})
    end
  end

  swagger_path :update do
    patch("/units/{id}")
    summary("Update a unit")
    description("Updates the attributes of an existing unit")
    consumes("application/json")
    produces("application/json")
    tag("Company / Unit")

    AinComBookingApi.CommonParameters.authorization()

    parameter(:id, :path, :string, "Unit ID", required: true)
    parameter(:unit, :body, Schema.ref(:UnitRequest), "Unit attributes to update")

    response(200, "Unit updated", Schema.ref(:Unit))
    response(404, "Unit not found")
    response(422, "Invalid input")
  end

  def update(conn, %{"id" => id} = params) do
    case Repo.get(Unit, id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Unit not found"})

      unit ->
        changeset = Unit.changeset(unit, Map.delete(params, "id"))

        case Repo.update(changeset) do
          {:ok, updated_unit} ->
            json(conn, updated_unit)

          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{errors: Ecto.Changeset.traverse_errors(changeset, &translate_error/1)})
        end
    end
  end

  swagger_path :index do
    get("/units")
    produces("application/json")
    tag("Company / Unit")

    AinComBookingApi.CommonParameters.authorization()
    AinComBookingApi.CommonParameters.sorting()
  end

  def index(conn, _params) do
    units = Repo.all(Unit)
    json(conn, units)
  end

  swagger_path :delete do
    delete("/units/{id}")
    summary("Delete unit")
    produces("application/json")
    tag("Company / Unit")

    AinComBookingApi.CommonParameters.authorization()

    parameter(:id, :path, :string, "Unit ID", required: true)

    response(204, "Unit deleted")
    response(404, "Unit not found")
  end

  def remove(conn, %{"id" => id}) do
    case Repo.get(Unit, id) do
      nil ->
        send_resp(conn, :not_found, "")

      unit ->
        Repo.delete!(unit)
        send_resp(conn, :no_content, "")
    end
  end

  def swagger_definitions do
    %{
      Unit:
        swagger_schema do
          title("Unit")
          description("Represents a unit")

          properties do
            id(:string, "Unit ID")
            name(:string)
            email(:string)
            phone(:string)
            description(:string)
            picture(:string)
            picture_path(:string)
            position(:integer)
            qty(:integer)
            is_active(:boolean)
            is_visible(:boolean)
            company_id(:string, "Company ID")
          end

          example(%{
            id: "unit-001",
            name: "Main Unit",
            email: "unit@example.com",
            phone: "010-1111-2222",
            description: "Core service unit",
            picture: "unit.png",
            picture_path: "/images/unit.png",
            position: 1,
            qty: 5,
            is_active: true,
            is_visible: true,
            company_id: "company-001"
          })
        end,
      UnitRequest:
        swagger_schema do
          title("UnitRequest")
          description("Payload for creating/updating a unit")

          properties do
            name(:string)
            email(:string)
            phone(:string)
            description(:string)
            picture(:string)
            picture_path(:string)
            position(:integer)
            qty(:integer)
            is_active(:boolean)
            is_visible(:boolean)
            company_id(:string)
          end

          example(%{
            name: "Main Unit",
            email: "unit@example.com",
            phone: "010-1111-2222",
            description: "Core service unit",
            picture: "unit.png",
            picture_path: "/images/unit.png",
            position: 1,
            qty: 5,
            is_active: true,
            is_visible: true,
            company_id: "company-001"
          })
        end
    }
  end
end
