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
    description("Fetches available slots within a date range. At least one of service_id or resource_id is required.")
    produces("application/json")
    tag("Company / Slot")

    AinComBookingApi.CommonParameters.authorization()

    parameters do
      service_id(:string, :query, "Service ID (optional)")
      resource_id(:string, :query, "Resource ID (optional)")
      from(:string, :query, "Start date (YYYY-MM-DD)", required: true)
      to(:string, :query, "End date (YYYY-MM-DD)", required: true)
    end

    response(200, "List of available slots")
  end

  def index(conn, %{"from" => from_str, "to" => to_str} = params) do
    service_id = normalize_optional_id(Map.get(params, "service_id"))
    resource_id = normalize_optional_id(Map.get(params, "resource_id"))

    if is_nil(service_id) and is_nil(resource_id) do
      conn
      |> put_status(:bad_request)
      |> json(%{error: "Required params: at least one of service_id or resource_id, plus from and to"})
    else
      do_index(conn, service_id, resource_id, from_str, to_str)
    end
  end

  def index(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Required params: from, to and at least one of service_id or resource_id"})
  end

  defp do_index(conn, service_id, resource_id, from_str, to_str) do
    with {:ok, from_date} <- Date.from_iso8601(from_str),
         {:ok, to_date} <- Date.from_iso8601(to_str) do
      from_dt = DateTime.new!(from_date, ~T[00:00:00], "Etc/UTC")
      to_dt = DateTime.new!(to_date, ~T[23:59:59], "Etc/UTC")

      query =
        from(s in CompanySlot,
          where: s.start_time >= ^from_dt and s.start_time <= ^to_dt and s.status == :available
        )

      query = if service_id, do: from(s in query, where: s.service_id == ^service_id), else: query
      query = if resource_id, do: from(s in query, where: s.resource_id == ^resource_id), else: query

      slots =
        Repo.all(from(s in query, order_by: [asc: s.start_time]))

      json(conn, slots)
    else
      _ ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Invalid date format. Use YYYY-MM-DD for from/to."})
    end
  end

  defp normalize_optional_id(nil), do: nil
  defp normalize_optional_id(""), do: nil
  defp normalize_optional_id(value), do: value

  swagger_path :create do
    post("/company/slots")
    summary("Create a new slot")

    description("""
    Add a new time slot.
    Cases:
    1) Service + Resource: {"service_id":"svc_123","resource_id":"res_123",...}
    2) Service only: {"service_id":"svc_123",...}
    3) Resource only: {"resource_id":"res_123",...}
    """)

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
            start_time(:string)
            end_time(:string)
            status(:string)
            service_id(:string)
            resource_id(:string)
          end

          example(%{
            id: "slot123",
            start_time: "2026-02-24T10:00:00Z",
            end_time: "2026-02-24T10:30:00Z",
            status: "available",
            service_id: "svc_123",
            resource_id: "res_123"
          })
        end,
      CompanySlotRequest:
        swagger_schema do
          title("CompanySlotRequest")

          description("""
          Attributes for creating or updating a slot.
          Examples:
          1) Service + Resource: {"start_time":"2026-02-24T10:00:00Z","end_time":"2026-02-24T10:30:00Z","status":"available","service_id":"svc_123","resource_id":"res_123"}
          2) Service only: {"start_time":"2026-02-24T10:00:00Z","end_time":"2026-02-24T10:30:00Z","status":"available","service_id":"svc_123"}
          3) Resource only: {"start_time":"2026-02-24T10:00:00Z","end_time":"2026-02-24T10:30:00Z","status":"available","resource_id":"res_123"}
          """)

          properties do
            start_time(:string)
            end_time(:string)
            status(:string)
            service_id(:string, "Optional when booking resource-only")
            resource_id(:string, "Optional when booking service-only")
          end

          example(%{
            start_time: "2026-02-24T10:00:00Z",
            end_time: "2026-02-24T10:30:00Z",
            status: "available",
            service_id: "svc_123",
            resource_id: "res_123"
          })
        end
    }
  end
end
