defmodule AinComBookingApi.Controllers.User.UserSlotController do
  use Phoenix.Controller
  use PhoenixSwagger

  import AinComBookingApi.Errors
  import Ecto.Query

  alias AinComBooking.Bookings.UserSlot
  alias AinComBooking.Repo

  def swagger_paths do
    [:index, :create, :update, :delete]
  end

  swagger_path :index do
    get("/user/slots")
    summary("List available user slots")
    description("Fetches available slots for a user service within a date range")
    produces("application/json")
    tag("User")

    AinComBookingApi.CommonParameters.authorization()

    parameters do
      service_id(:string, :query, "Service ID", required: true)
      from(:string, :query, "Start date (YYYY-MM-DD)", required: true)
      to(:string, :query, "End date (YYYY-MM-DD)", required: true)
    end

    response(200, "List of user slots")
  end

  def index(conn, %{"service_id" => service_id, "from" => from_str, "to" => to_str}) do
    {:ok, from_date} = Date.from_iso8601(from_str)
    {:ok, to_date} = Date.from_iso8601(to_str)

    slots = Repo.all(from(s in UserSlot, where: s.service_id == ^service_id and s.date >= ^from_date and s.date <= ^to_date and s.status == :available))

    json(conn, slots)
  end

  swagger_path :create do
    post("/user/slots")
    summary("Create a user slot")
    description("Add a new time slot for user services")
    produces("application/json")
    consumes("application/json")
    tag("User")

    AinComBookingApi.CommonParameters.authorization()

    parameter(:slot, :body, Schema.ref(:UserSlotRequest), "User Slot attributes")

    response(201, "Slot created", Schema.ref(:UserSlot))
    response(422, "Validation failed")
  end

  def create(conn, params) do
    changeset = UserSlot.changeset(%UserSlot{}, params)

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
    patch("/user/slots/{id}")
    summary("Update a user slot")
    description("Modify an existing user slot")
    produces("application/json")
    consumes("application/json")
    tag("User")

    AinComBookingApi.CommonParameters.authorization()

    parameter(:id, :path, :string, "Slot ID", required: true)
    parameter(:slot, :body, Schema.ref(:UserSlotRequest), "Slot attributes to update")

    response(200, "Slot updated", Schema.ref(:UserSlot))
    response(404, "Slot not found")
    response(422, "Invalid input")
  end

  def update(conn, %{"id" => id} = params) do
    case Repo.get(UserSlot, id) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "Slot not found"})

      slot ->
        changeset = UserSlot.changeset(slot, Map.delete(params, "id"))

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
    delete("/user/slots/{id}")
    summary("Delete a user slot")
    produces("application/json")
    tag("User")

    AinComBookingApi.CommonParameters.authorization()

    parameter(:id, :path, :string, "UserSlot ID", required: true)

    response(204, "UserSlot deleted")
    response(404, "UserSlot not found")
  end

  def remove(conn, %{"id" => id}) do
    case Repo.get(UserSlot, id) do
      nil ->
        send_resp(conn, :not_found, "")

      slot ->
        Repo.delete!(slot)
        send_resp(conn, :no_content, "")
    end
  end

  def swagger_definitions do
    %{
      UserSlot:
        swagger_schema do
          title("UserSlot")
          description("A slot for user booking")

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
            id: "uslot123",
            date: "2025-08-01",
            start_time: "09:00:00",
            end_time: "09:30:00",
            status: "available",
            capacity: 3,
            booked_count: 1
          })
        end,
      UserSlotRequest:
        swagger_schema do
          title("UserSlotRequest")
          description("Attributes for creating or updating a user slot")

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
            start_time: "09:00:00",
            end_time: "09:30:00",
            status: "available",
            capacity: 3,
            booked_count: 0
          })
        end
    }
  end
end
