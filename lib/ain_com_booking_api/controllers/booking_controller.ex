defmodule AinComBookingApi.Controllers.BookingController do
  use Phoenix.Controller
  use PhoenixSwagger

  import AinComBookingApi.Errors
  import Ecto.Query

  alias AinComBooking.Bookings.Booking
  alias AinComBooking.Bookings.Slot
  alias AinComBooking.Repo

  # POST /api/bookings
  swagger_path :create do
    post("/bookings")
    summary("Create booking")
    description("Create a booking for a given slot")
    produces("application/json")
    consumes("application/json")

    # 재사용 파라미터 예시: JWT와 device_token 헤더
    AinComBookingApi.CommonParameters.authorization()

    parameter(:booking, :body, Schema.ref(:BookingRequest), "Booking attributes")

    response(201, "Booking created", Schema.ref(:Booking))
    response(409, "Slot already taken or unavailable")
  end

  def create(conn, %{"slot_id" => slot_id, "customer_name" => name, "email" => email, "phone" => phone}) do
    result =
      Repo.transaction(fn ->
        slot =
          Slot
          |> where([s], s.id == ^slot_id)
          |> lock("FOR UPDATE")
          |> Repo.one()

        if slot == nil or slot.status != "available" do
          Repo.rollback(:unavailable)
        end

        booking =
          %Booking{}
          |> Booking.changeset(%{
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
        |> json(%{error: "Slot already taken or unavailable"})

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: inspect(reason)})
    end
  end

  # PATCH /api/bookings/{id}
  swagger_path :update do
    PhoenixSwagger.Path.patch("/bookings/{id}")
    summary("Update a booking")
    description("Updates the customer details or status of an existing booking")
    consumes("application/json")
    produces("application/json")

    AinComBookingApi.CommonParameters.authorization()

    parameter(:id, :path, :string, "Booking ID", required: true)
    parameter(:booking, :body, Schema.ref(:BookingRequest), "Booking attributes to update")

    response(200, "Booking updated", Schema.ref(:Booking))
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

      %Booking{} = booking ->
        # `params` may include keys like "customer_name", "email", etc.
        changeset = Booking.changeset(booking, Map.delete(params, "id"))

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
    get("/bookings")
    produces("application/json")
    AinComBookingApi.CommonParameters.authorization()
    AinComBookingApi.CommonParameters.sorting()

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
    PhoenixSwagger.Path.delete("/bookings/{id}")
    summary("Delete booking")
    produces("application/json")

    AinComBookingApi.CommonParameters.authorization()

    parameter(:id, :path, :string, "Booking ID", required: true)

    response(204, "Booking deleted")
    response(404, "Booking not found")
  end

  def delete(conn, %{"id" => id}) do
    case Repo.get(Booking, id) do
      nil ->
        send_resp(conn, :not_found, "")

      booking ->
        Repo.delete!(booking)
        send_resp(conn, :no_content, "")
    end
  end

  def swagger_definitions do
    %{
      Booking:
        swagger_schema do
          title("Booking")
          description("Represents a booking record")

          properties do
            id(:string, "Booking ID")
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
      BookingRequest:
        swagger_schema do
          title("BookingRequest")
          description("Payload for creating a booking")

          properties do
            slot_id(:string, "Slot ID", required: true)
            customer_name(:string, "Customer name", required: true)
            email(:string, "Email", required: true)
            phone(:string, "Phone", required: true)
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
