defmodule AinComBookingApi.Controllers.Company.CompanyBookingController do
  use Phoenix.Controller
  use PhoenixSwagger

  import AinComBookingApi.Errors
  import Ecto.Query

  alias AinComBooking.Bookings.CompanyBooking
  alias AinComBooking.Bookings.CompanySlot
  alias AinComBooking.Repo

  def swagger_paths do
    [
      :create,
      :update,
      :index,
      :delete
    ]
  end

  # POST /api/bookings
  swagger_path :create do
    post("/company/bookings")
    summary("Create booking")
    description("Create a booking for a given slot")
    produces("application/json")
    consumes("application/json")
    tag("Company / Booking")

    # 재사용 파라미터 예시: JWT와 X-Device-Token 헤더
    AinComBookingApi.CommonParameters.authorization()

    parameter(:booking, :body, Schema.ref(:CompanyBookingRequest), "CompanyBooking attributes")

    response(201, "Booking created", Schema.ref(:CompanyBooking))
    response(409, "Slot already taken or unavailable")
  end

  def create(conn, %{"slot_id" => slot_id, "customer_name" => name, "email" => email, "phone" => phone}) do
    result =
      Repo.transaction(fn ->
        slot =
          CompanySlot
          |> where([s], s.id == ^slot_id)
          |> lock("FOR UPDATE")
          |> Repo.one()

        if slot == nil or slot.status != "available" do
          Repo.rollback(:unavailable)
        end

        # %Booking{}
        booking =
          CompanyBooking
          # |> struct(%{})
          |> CompanyBooking.changeset(%{
            slot_id: slot.id,
            customer_name: name,
            email: email,
            phone: phone,
            status: "confirmed"
          })
          |> Repo.insert!()

        Repo.update!(Ecto.Changeset.change(slot, status: "booked"))

        booking
      end)

    case result do
      {:ok, booking} ->
        json(conn, booking)

      {:error, :unavailable} ->
        conn
        |> put_status(:conflict)
        |> json(%{error: "CompanySlot already taken or unavailable"})

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: inspect(reason)})
    end
  end

  # PATCH /api/bookings/{id}
  swagger_path :update do
    patch("/company/bookings/{id}")
    summary("Update a booking")
    description("Updates the customer details or status of an existing booking")
    consumes("application/json")
    produces("application/json")
    tag("Company / Booking")

    AinComBookingApi.CommonParameters.authorization()

    parameter(:id, :path, :string, "CompanyBooking ID", required: true)
    parameter(:booking, :body, Schema.ref(:CompanyBookingRequest), "CompanyBooking attributes to update")

    response(200, "Booking updated", Schema.ref(:CompanyBooking))
    response(404, "Booking not found")
    response(409, "Slot already taken or unavailable")
  end

  def update(conn, %{"id" => id} = params) do
    # optional: ensure the booking exists
    case Repo.get(Booking, id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Booking not found"})

      booking ->
        # `params` may include keys like "customer_name", "email", etc.
        changeset = CompanyBooking.changeset(booking, Map.delete(params, "id"))

        case Repo.update(changeset) do
          {:ok, updated_booking} ->
            json(conn, updated_booking)

          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{errors: Ecto.Changeset.traverse_errors(changeset, &translate_error/1)})
        end
    end
  end

  swagger_path :index do
    get("/company/bookings")
    produces("application/json")
    AinComBookingApi.CommonParameters.authorization()
    AinComBookingApi.CommonParameters.sorting()
    tag("Company / Booking")

    parameters do
      company_id(:string, :query, "The company id")
    end
  end

  def index(conn, _params) do
    bookings = Repo.all(Booking)
    json(conn, bookings)
  end

  # DELETE /api/bookings/{id}
  swagger_path :delete do
    delete("/company/bookings/{id}")
    summary("Delete booking")
    produces("application/json")
    tag("Company / Booking")

    AinComBookingApi.CommonParameters.authorization()

    parameter(:id, :path, :string, "CompanyBooking ID", required: true)

    response(204, "CompanyBooking deleted")
    response(404, "CompanyBooking not found")
  end

  def remove(conn, %{"id" => id}) do
    case Repo.get(CompanyBooking, id) do
      nil ->
        send_resp(conn, :not_found, "")

      booking ->
        Repo.delete!(booking)
        send_resp(conn, :no_content, "")
    end
  end

  def swagger_definitions do
    %{
      CompanyBooking:
        swagger_schema do
          title("CompanyBooking")
          description("Represents a booking record")

          properties do
            id(:string, "CompanyBooking ID")
            slot_id(:string, "Slot ID")
            customer_name(:string)
            email(:string)
            phone(:string)
            status(:string)
          end

          example(%{
            id: "12c9be95-2c09-4cc2-9a24-6c42f8fae54d",
            slot_id: "27d9be95-2c09-4cc2-9a24-6c42f8fae54d",
            customer_name: "John Doe",
            email: "john@example.com",
            phone: "010-0000-0000",
            status: "confirmed"
          })
        end,
      CompanyBookingRequest:
        swagger_schema do
          title("CompanyBookingRequest")
          description("Payload for creating a booking")

          properties do
            slot_id(:string, "Slot ID")
            customer_name(:string, "Customer name")
            email(:string, "Email")
            phone(:string, "Phone")
          end

          example(%{
            slot_id: "27d9be95-2c09-4cc2-9a24-6c42f8fae54d",
            customer_name: "John Doe",
            email: "john@example.com",
            phone: "010-0000-0000"
          })
        end
    }
  end
end
