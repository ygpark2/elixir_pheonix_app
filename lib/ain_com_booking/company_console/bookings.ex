defmodule AinComBooking.CompanyConsole.Bookings do
  @moduledoc false

  import Ecto.Query, warn: false

  alias AinComBooking.Accounts.User
  alias AinComBooking.Bookings.CompanyBooking
  alias AinComBooking.CompanyConsole
  alias AinComBooking.CompanyConsole.BookingPage
  alias AinComBooking.CompanyConsole.SlotGeneration
  alias AinComBooking.Repo
  alias Decimal, as: D

  @day_seconds 24 * 60 * 60

  def list_company_bookings(%User{} = user) do
    Repo.all(
      from([booking, slot, service, resource] in company_bookings_query(user),
        order_by: [desc: booking.inserted_at],
        preload: [slot: slot, service: service, resource: resource]
      )
    )
  end

  def list_company_bookings_for_service(%User{} = user, service_id) when is_binary(service_id) do
    Repo.all(
      from([booking, slot, service, resource] in company_bookings_query(user),
        where: booking.service_id == ^service_id,
        order_by: [desc: booking.inserted_at],
        preload: [slot: slot, service: service, resource: resource]
      )
    )
  end

  def list_company_bookings_for_resource(%User{} = user, resource_id) when is_binary(resource_id) do
    Repo.all(
      from([booking, slot, service, resource] in company_bookings_query(user),
        where: booking.resource_id == ^resource_id,
        order_by: [desc: booking.inserted_at],
        preload: [slot: slot, service: service, resource: resource]
      )
    )
  end

  def confirmed_company_booking_counts_by_slot_ids(%User{} = user, slot_ids) when is_list(slot_ids) do
    normalized_slot_ids =
      slot_ids
      |> Enum.filter(&is_binary/1)
      |> Enum.uniq()

    if normalized_slot_ids == [] do
      %{}
    else
      Repo.all(
        from([booking, _slot, _service, _resource] in company_bookings_query(user),
          where: booking.slot_id in ^normalized_slot_ids and booking.status == "confirmed",
          group_by: booking.slot_id,
          select: {booking.slot_id, count(booking.id)}
        )
      )
      |> Map.new()
    end
  end

  def get_company_booking(%User{} = user, id) when is_binary(id) do
    Repo.one(
      from([booking, slot, service, resource] in company_bookings_query(user),
        where: booking.id == ^id,
        preload: [slot: slot, service: service, resource: resource]
      )
    )
  end

  def change_company_booking(%CompanyBooking{} = booking, attrs \\ %{}) do
    CompanyBooking.changeset(booking, normalize_booking_attrs(attrs))
  end

  def update_company_booking(%User{} = user, %CompanyBooking{} = booking, attrs) when is_map(attrs) do
    case get_company_booking(user, booking.id) do
      nil ->
        {:error, :not_found}

      %CompanyBooking{} = owned_booking ->
        owned_booking
        |> CompanyBooking.changeset(normalize_booking_update_attrs(attrs))
        |> SlotGeneration.validate_booking_status_capacity()
        |> Repo.update()
        |> preload_booking()
        |> sync_slot_status_after_booking_update(owned_booking.slot_id)
    end
  end

  def recent_company_bookings(%User{} = user, limit \\ 6) when is_integer(limit) and limit > 0 do
    Repo.all(
      from([booking, slot, service, resource] in company_bookings_query(user),
        order_by: [desc: booking.inserted_at],
        limit: ^limit,
        preload: [slot: slot, service: service, resource: resource]
      )
    )
  end

  def count_company_bookings(%User{} = user) do
    Repo.aggregate(company_bookings_query(user), :count, :id)
  end

  def recent_booking_metrics(%User{} = user) do
    cutoff =
      NaiveDateTime.utc_now()
      |> NaiveDateTime.add(-7 * @day_seconds, :second)
      |> NaiveDateTime.truncate(:second)

    totals =
      Repo.all(
        from([booking, _slot, _service, _resource] in company_bookings_query(user),
          where: booking.inserted_at >= ^cutoff,
          select: {booking.total_price, booking.currency}
        )
      )

    currencies =
      totals
      |> Enum.map(fn {_total_price, currency} -> currency end)
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()

    %{
      bookings: length(totals),
      revenue: Enum.reduce(totals, D.new(0), fn {total_price, _currency}, acc -> D.add(acc, total_price || D.new(0)) end),
      currency: single_currency(currencies)
    }
  end

  def create_booking_from_page(%BookingPage{} = page, attrs) when is_map(attrs) do
    slot_id = map_get(attrs, "slot_id")

    fn ->
      with {:ok, slot, booking_count} <- SlotGeneration.resolve_booking_slot(page, slot_id),
           {:ok, service} <- SlotGeneration.get_booking_service(slot),
           {:ok, resource} <- SlotGeneration.get_booking_resource(slot),
           :ok <- SlotGeneration.ensure_slot_matches_page(page, slot),
           {service, resource} <- SlotGeneration.scope_booking_targets(page, service, resource),
           {:ok, pricing} <- SlotGeneration.build_pricing(service, resource),
           {:ok, booking} <- insert_booking(slot, pricing, attrs) do
        SlotGeneration.maybe_close_full_slot(slot, booking_count + 1)
        booking
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end
    |> Repo.transaction()
    |> case do
      {:ok, booking} -> {:ok, booking}
      {:error, reason} -> {:error, reason}
    end
  end

  def booking_error_message(:unavailable), do: "That slot is no longer available."
  def booking_error_message(:slot_full), do: "That slot has reached its booking limit."
  def booking_error_message(:slot_not_shareable), do: "That slot does not belong to this booking page."
  def booking_error_message(:currency_mismatch), do: "That slot has inconsistent pricing data."
  def booking_error_message(%Ecto.Changeset{}), do: "Please complete the booking form."
  def booking_error_message(_), do: "Booking could not be completed."

  defp company_bookings_query(%User{} = user) do
    company_id = CompanyConsole.ensure_company!(user).id

    from(booking in CompanyBooking,
      left_join: slot in assoc(booking, :slot),
      left_join: service in assoc(booking, :service),
      left_join: resource in assoc(booking, :resource),
      where:
        (not is_nil(service.id) and service.company_id == ^company_id) or
          (not is_nil(resource.id) and resource.company_id == ^company_id)
    )
  end

  defp single_currency([]), do: "KRW"
  defp single_currency([currency]), do: currency
  defp single_currency(_currencies), do: nil

  defp insert_booking(slot, pricing, attrs) do
    %CompanyBooking{}
    |> CompanyBooking.changeset(%{
      slot_id: slot.id,
      customer_name: map_get(attrs, "customer_name"),
      email: map_get(attrs, "email"),
      phone: map_get(attrs, "phone"),
      status: "confirmed",
      service_id: pricing.service_id,
      resource_id: pricing.resource_id,
      service_price: pricing.service_price,
      resource_price: pricing.resource_price,
      total_price: pricing.total_price,
      currency: pricing.currency
    })
    |> Repo.insert()
    |> case do
      {:ok, booking} -> {:ok, booking}
      {:error, changeset} -> {:error, changeset}
    end
  end

  defp sync_slot_status_after_booking_update({:ok, booking}, slot_id) do
    SlotGeneration.sync_slot_status(slot_id)
    {:ok, booking}
  end

  defp sync_slot_status_after_booking_update(other, _slot_id), do: other

  defp preload_booking({:ok, %CompanyBooking{} = booking}) do
    {:ok, Repo.preload(booking, [:slot, :service, :resource])}
  end

  defp preload_booking(other), do: other

  defp normalize_booking_attrs(attrs) do
    attrs
    |> stringify_keys()
    |> Map.delete("id")
  end

  defp normalize_booking_update_attrs(attrs) do
    attrs
    |> normalize_booking_attrs()
    |> Map.take(["customer_name", "email", "phone", "status"])
  end

  defp map_get(map, key) do
    Map.get(map, key) || Map.get(map, String.to_existing_atom(key))
  rescue
    ArgumentError -> nil
  end

  defp stringify_keys(attrs) do
    Map.new(attrs, fn {key, value} -> {to_string(key), value} end)
  end
end
