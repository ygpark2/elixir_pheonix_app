defmodule AinComBookingWeb.BookingController do
  use AinComBookingWeb, :controller

  import Ecto.Query

  alias AinComBookingApi.Bookings.Booking
  alias AinComBookingApi.Bookings.Slot
  alias AinComBookingApi.Repo

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

  def index(conn, _params) do
    bookings = Repo.all(Booking)
    json(conn, bookings)
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
end
