defmodule AinComBookingApi.Controllers.User.UserBookingController do
  use Phoenix.Controller
  use PhoenixSwagger

  import AinComBookingApi.Errors
  import Ecto.Query

  alias AinComBooking.Bookings.UserBooking
  alias AinComBooking.Bookings.UserSlot
  alias AinComBooking.Catalog.UserResource
  alias AinComBooking.Catalog.UserService
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
    post("/user/bookings")
    summary("Create booking")

    description("""
    Create a booking for a given slot.
    Cases:
    1) Service + Resource
    2) Service only
    3) Resource only
    """)

    produces("application/json")
    consumes("application/json")
    tag("User")

    AinComBookingApi.CommonParameters.authorization()

    parameter(:booking, :body, Schema.ref(:UserBookingRequest), "Booking attributes")

    response(201, "Booking created", Schema.ref(:UserBooking))
    response(409, "Slot already taken or unavailable")
  end

  def create(conn, %{"slot_id" => slot_id, "customer_name" => name, "email" => email, "phone" => phone} = params) do
    requested_service_id = normalize_optional_id(Map.get(params, "service_id"))
    requested_resource_id = normalize_optional_id(Map.get(params, "resource_id"))

    result =
      Repo.transaction(fn ->
        slot =
          UserSlot
          |> where([s], s.id == ^slot_id)
          |> lock("FOR UPDATE")
          |> Repo.one()

        if slot == nil or slot.status != :available do
          Repo.rollback(:unavailable)
        end

        with :ok <- ensure_target_match(slot.service_id, requested_service_id, :service_mismatch),
             :ok <- ensure_target_match(slot.resource_id, requested_resource_id, :resource_mismatch),
             {:ok, booking_targets} <-
               resolve_booking_targets(slot, requested_service_id, requested_resource_id),
             {:ok, pricing} <- resolve_pricing(booking_targets.service_id, booking_targets.resource_id) do
          booking =
            UserBooking
            |> UserBooking.changeset(%{
              slot_id: slot.id,
              customer_name: name,
              email: email,
              phone: phone,
              status: "confirmed",
              service_id: booking_targets.service_id,
              resource_id: booking_targets.resource_id,
              service_price: pricing.service_price,
              resource_price: pricing.resource_price,
              total_price: pricing.total_price,
              currency: pricing.currency
            })
            |> Repo.insert!()

          Repo.update!(Ecto.Changeset.change(slot, status: :booked))

          booking
        else
          {:error, reason} -> Repo.rollback(reason)
        end
      end)

    case result do
      {:ok, booking} ->
        json(conn, booking)

      {:error, :unavailable} ->
        conn
        |> put_status(:conflict)
        |> json(%{error: "UserSlot already taken or unavailable"})

      {:error, :service_mismatch} ->
        conn
        |> put_status(:conflict)
        |> json(%{error: "Requested service_id does not match slot configuration"})

      {:error, :resource_mismatch} ->
        conn
        |> put_status(:conflict)
        |> json(%{error: "Requested resource_id does not match slot configuration"})

      {:error, :target_required} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Booking requires at least one of service_id or resource_id"})

      {:error, :service_not_found} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "service_id does not exist"})

      {:error, :resource_not_found} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "resource_id does not exist"})

      {:error, :currency_mismatch} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "service and resource currencies do not match"})

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: inspect(reason)})
    end
  end

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
    case Repo.get(UserBooking, id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "UserBooking not found"})

      booking ->
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
  end

  def index(conn, _params) do
    bookings = Repo.all(UserBooking)
    json(conn, bookings)
  end

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
            service_id(:string, "Service ID")
            resource_id(:string, "Resource ID")
            customer_name(:string)
            email(:string)
            phone(:string)
            status(:string)
            service_price(:number)
            resource_price(:number)
            total_price(:number)
            currency(:string)
          end

          example(%{
            id: "12c9be95-2c09-4cc2-9a24-6c42f8fae54d",
            slot_id: "27d9be95-2c09-4cc2-9a24-6c42f8fae54d",
            service_id: "svc-123",
            resource_id: "res-123",
            customer_name: "John Doe",
            email: "john@example.com",
            phone: "010-0000-0000",
            status: "confirmed",
            service_price: 35_000,
            resource_price: 10_000,
            total_price: 45_000,
            currency: "KRW"
          })
        end,
      UserBookingRequest:
        swagger_schema do
          title("UserBookingRequest")

          description("""
          Payload for creating a booking. At least one of service_id or resource_id must be present.
          Examples:
          1) Service + Resource: {"slot_id":"slot_123","service_id":"svc_123","resource_id":"res_123","customer_name":"John Doe","email":"john@example.com","phone":"010-0000-0000"}
          2) Service only: {"slot_id":"slot_123","service_id":"svc_123","customer_name":"John Doe","email":"john@example.com","phone":"010-0000-0000"}
          3) Resource only: {"slot_id":"slot_123","resource_id":"res_123","customer_name":"John Doe","email":"john@example.com","phone":"010-0000-0000"}
          """)

          properties do
            slot_id(:string, "Slot ID")
            service_id(:string, "Optional service ID")
            resource_id(:string, "Optional resource ID")
            customer_name(:string, "Customer name")
            email(:string, "Email")
            phone(:string, "Phone")
          end

          required([:slot_id, :customer_name, :email, :phone])

          example(%{
            slot_id: "slot_123",
            service_id: "svc_123",
            resource_id: "res_123",
            customer_name: "John Doe",
            email: "john@example.com",
            phone: "010-0000-0000"
          })
        end
    }
  end

  defp ensure_target_match(nil, _requested, _reason), do: :ok
  defp ensure_target_match(_slot_value, nil, _reason), do: :ok
  defp ensure_target_match(slot_value, requested_value, _reason) when slot_value == requested_value, do: :ok
  defp ensure_target_match(_slot_value, _requested_value, reason), do: {:error, reason}

  defp resolve_booking_targets(slot, requested_service_id, requested_resource_id) do
    service_id = slot.service_id || requested_service_id
    resource_id = slot.resource_id || requested_resource_id

    if is_nil(service_id) and is_nil(resource_id) do
      {:error, :target_required}
    else
      {:ok, %{service_id: service_id, resource_id: resource_id}}
    end
  end

  defp resolve_pricing(service_id, resource_id) do
    with {:ok, service} <- fetch_service(service_id),
         {:ok, resource} <- fetch_resource(resource_id),
         {:ok, currency} <- resolve_currency(service, resource) do
      service_price = decimal_or_zero(service && service.price)
      resource_price = decimal_or_zero(resource && resource.price)
      total_price = Decimal.add(service_price, resource_price)

      {:ok,
       %{
         service_price: service_price,
         resource_price: resource_price,
         total_price: total_price,
         currency: currency
       }}
    end
  end

  defp fetch_service(nil), do: {:ok, nil}

  defp fetch_service(id) do
    case Repo.get(UserService, id) do
      nil -> {:error, :service_not_found}
      service -> {:ok, service}
    end
  end

  defp fetch_resource(nil), do: {:ok, nil}

  defp fetch_resource(id) do
    case Repo.get(UserResource, id) do
      nil -> {:error, :resource_not_found}
      resource -> {:ok, resource}
    end
  end

  defp resolve_currency(nil, nil), do: {:ok, "KRW"}

  defp resolve_currency(%{currency: service_currency}, nil), do: {:ok, service_currency || "KRW"}
  defp resolve_currency(nil, %{currency: resource_currency}), do: {:ok, resource_currency || "KRW"}

  defp resolve_currency(%{currency: service_currency}, %{currency: resource_currency}) do
    cond do
      is_nil(service_currency) or service_currency == "" ->
        {:ok, resource_currency || "KRW"}

      is_nil(resource_currency) or resource_currency == "" ->
        {:ok, service_currency}

      service_currency == resource_currency ->
        {:ok, service_currency}

      true ->
        {:error, :currency_mismatch}
    end
  end

  defp decimal_or_zero(nil), do: Decimal.new("0")
  defp decimal_or_zero(%Decimal{} = value), do: value
  defp decimal_or_zero(value) when is_binary(value), do: Decimal.new(value)
  defp decimal_or_zero(value) when is_integer(value), do: Decimal.new(value)
  defp decimal_or_zero(value) when is_float(value), do: Decimal.from_float(value)

  defp normalize_optional_id(nil), do: nil
  defp normalize_optional_id(""), do: nil
  defp normalize_optional_id(value), do: value
end
