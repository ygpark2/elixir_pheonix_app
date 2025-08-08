defmodule AinComBookingApi.Controllers.User.UserBookingController do
  use Phoenix.Controller
  use PhoenixSwagger

  import AinComBookingApi.Errors
  import Ecto.Query

  alias AinComBooking.Bookings.UserBooking
  alias AinComBooking.Bookings.UserSlot
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
    post("/user/bookings")
    summary("Create booking")
    description("Create a booking for a given slot")
    produces("application/json")
    consumes("application/json")
    tag("User")

    # 재사용 파라미터 예시: JWT와 device_token 헤더
    AinComBookingApi.CommonParameters.authorization()

    parameter(:booking, :body, Schema.ref(:UserBookingRequest), "Booking attributes")

    response(201, "Booking created", Schema.ref(:UserBooking))
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

        # %Booking{}
        booking =
          UserBooking
          # |> struct(%{})
          |> UserBooking.changeset(%{
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
    patch("/user/bookings/{id}")
    summary("Update a booking")
    description("Updates the customer details or status of an existing booking")
    consumes("application/json")
    produces("application/json")
    tag("User")

    AinComBookingApi.CommonParameters.authorization()

    parameter(:id, :path, :string, "UserBooking ID", required: true)
    parameter(:booking, :body, Schema.ref(:UserBookingRequest), "UserBooking attributes to update")

    response(200, "Booking updated", Schema.ref(:UserBooking))
    response(404, "Booking not found")
    response(409, "Slot already taken or unavailable")
  end

  def update(conn, %{"id" => id} = params) do
    # optional: ensure the booking exists
    case Repo.get(UserBooking, id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "UserBooking not found"})

      booking ->
        # `params` may include keys like "customer_name", "email", etc.
        changeset = UserBooking.changeset(booking, Map.delete(params, "id"))

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
    get("/user/bookings")
    produces("application/json")
    tag("User")

    AinComBookingApi.CommonParameters.authorization()
    AinComBookingApi.CommonParameters.sorting()

    parameters do
      company_id(:string, :query, "The company id")
    end
  end

  def index(conn, _params) do
    bookings = Repo.all(UserBooking)
    json(conn, bookings)
  end

  # DELETE /api/bookings/{id}
  swagger_path :delete do
    delete("/user/bookings/{id}")
    summary("Delete booking")
    produces("application/json")
    tag("User")

    AinComBookingApi.CommonParameters.authorization()

    parameter(:id, :path, :string, "Booking ID", required: true)

    response(204, "UserBooking deleted")
    response(404, "UserBooking not found")
  end

  def remove(conn, %{"id" => id}) do
    case Repo.get(UserBooking, id) do
      nil ->
        send_resp(conn, :not_found, "")

      booking ->
        Repo.delete!(booking)
        send_resp(conn, :no_content, "")
    end
  end

  def swagger_definitions do
    %{
      UserBooking:
        swagger_schema do
          title("UserBooking")
          description("Represents a user booking record")

          properties do
            id(:string, "UserBooking ID")
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
      UserBookingRequest:
        swagger_schema do
          title("UserBookingRequest")
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
