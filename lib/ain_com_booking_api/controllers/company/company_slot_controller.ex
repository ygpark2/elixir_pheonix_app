defmodule AinComBookingApi.Controllers.Company.CompanySlotController do
  use Phoenix.Controller
  use PhoenixSwagger

  import AinComBookingApi.Errors
  import Ecto.Query

  alias AinComBooking.Bookings.CompanySlot
  alias AinComBooking.Repo

  def swagger_paths do
    [:index, :create, :update, :delete]
  end

  swagger_path :index do
    get("/company/slots")
    summary("List available slots")
    description("Fetches available slots within a date range for a service")
    produces("application/json")
    tag("Company / Slot")

    AinComBookingApi.CommonParameters.authorization()

    parameters do
      service_id(:string, :query, "Service ID", required: true)
      from(:string, :query, "Start date (YYYY-MM-DD)", required: true)
      to(:string, :query, "End date (YYYY-MM-DD)", required: true)
    end

    response(200, "List of available slots")
  end

  def index(conn, %{"service_id" => service_id, "from" => from_str, "to" => to_str}) do
    {:ok, from_date} = Date.from_iso8601(from_str)
    {:ok, to_date} = Date.from_iso8601(to_str)

    from_dt = DateTime.new!(from_date, ~T[00:00:00], "Asia/Seoul")
    to_dt = DateTime.new!(to_date, ~T[23:59:59], "Asia/Seoul")

    slots = Repo.all(from(s in CompanySlot, where: s.service_id == ^service_id and s.date >= ^from_date and s.date <= ^to_date and s.status == :available))

    json(conn, slots)
  end

  swagger_path :create do
    post("/company/slots")
    summary("Create a new slot")
    description("Add a new time slot")
    produces("application/json")
    consumes("application/json")
    tag("Company / Slot")

    AinComBookingApi.CommonParameters.authorization()

    parameter(:slot, :body, Schema.ref(:CompanySlotRequest), "Slot attributes")

    response(201, "Slot created", Schema.ref(:CompanySlot))
    response(422, "Validation failed")
  end

  def create(conn, params) do
    changeset = CompanySlot.changeset(%CompanySlot{}, params)

    case Repo.insert(changeset) do
      {:ok, slot} ->
        conn |> put_status(:created) |> json(slot)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: Ecto.Changeset.traverse_errors(changeset, &translate_error/1)})
    end
  end

  swagger_path :update do
    patch("/company/slots/{id}")
    summary("Update a slot")
    description("Modify an existing slot")
    produces("application/json")
    consumes("application/json")
    tag("Company / Slot")

    AinComBookingApi.CommonParameters.authorization()

    parameter(:id, :path, :string, "CompanySlot ID", required: true)
    parameter(:slot, :body, Schema.ref(:CompanySlotRequest), "Slot attributes to update")

    response(200, "CompanySlot updated", Schema.ref(:CompanySlot))
    response(404, "CompanySlot not found")
    response(422, "Invalid input")
  end

  def update(conn, %{"id" => id} = params) do
    case Repo.get(CompanySlot, id) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "CompanySlot not found"})

      slot ->
        changeset = CompanySlot.changeset(slot, Map.delete(params, "id"))

        case Repo.update(changeset) do
          {:ok, updated_slot} ->
            json(conn, updated_slot)

          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{errors: Ecto.Changeset.traverse_errors(changeset, &translate_error/1)})
        end
    end
  end

  swagger_path :delete do
    delete("/company/slots/{id}")
    summary("Delete a slot")
    produces("application/json")
    tag("Company / Slot")

    AinComBookingApi.CommonParameters.authorization()

    parameter(:id, :path, :string, "CompanySlot ID", required: true)

    response(204, "CompanySlot deleted")
    response(404, "CompanySlot not found")
  end

  def remove(conn, %{"id" => id}) do
    case Repo.get(CompanySlot, id) do
      nil ->
        send_resp(conn, :not_found, "")

      slot ->
        Repo.delete!(slot)
        send_resp(conn, :no_content, "")
    end
  end

  def swagger_definitions do
    %{
      CompanySlot:
        swagger_schema do
          title("CompanySlot")
          description("A slot for booking")

          properties do
            id(:string)
            date(:string)
            start_time(:string)
            end_time(:string)
            status(:string)
            capacity(:integer)
            booked_count(:integer)
          end

          example(%{
            id: "slot123",
            date: "2025-08-01",
            start_time: "10:00:00",
            end_time: "10:30:00",
            status: "available",
            capacity: 4,
            booked_count: 1
          })
        end,
      CompanySlotRequest:
        swagger_schema do
          title("CompanySlotRequest")
          description("Attributes for creating or updating a slot")

          properties do
            date(:string)
            start_time(:string)
            end_time(:string)
            status(:string)
            capacity(:integer)
            booked_count(:integer)
          end

          example(%{
            date: "2025-08-01",
            start_time: "10:00:00",
            end_time: "10:30:00",
            status: "available",
            capacity: 4,
            booked_count: 0
          })
        end
    }
  end
end
