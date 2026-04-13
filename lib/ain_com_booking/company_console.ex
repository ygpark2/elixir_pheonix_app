defmodule AinComBooking.CompanyConsole do
  @moduledoc false

  import Ecto.Query, warn: false

  alias AinComBooking.Accounts.User
  alias AinComBooking.Bookings.CompanyBooking
  alias AinComBooking.Bookings.CompanySlot
  alias AinComBooking.Catalog.Company
  alias AinComBooking.Catalog.CompanyResource
  alias AinComBooking.Catalog.CompanyService
  alias AinComBooking.CompanyConsole.BookingPage
  alias AinComBooking.Repo
  alias Decimal, as: D
  alias Ecto.Adapters.SQLite3

  @day_seconds 24 * 60 * 60
  @default_company_timezone "Asia/Seoul"

  def get_company_for_user(%User{} = user) do
    Repo.one(from(company in Company, where: company.user_id == ^user.id, limit: 1, order_by: [asc: company.inserted_at]))
  end

  def ensure_company!(%User{} = user) do
    case get_company_for_user(user) do
      nil ->
        %Company{}
        |> Company.changeset(%{
          login: company_login(user),
          name: company_name(user),
          user_id: user.id,
          email: user.email,
          phone: user.phone,
          timezone: @default_company_timezone
        })
        |> Repo.insert!()

      company ->
        company
    end
  end

  def dashboard_snapshot(%User{} = user) do
    services = list_company_services(user)
    resources = list_company_resources(user)
    slots = list_company_slots(user)
    pages = list_booking_pages(user)
    published_pages = Enum.count(pages, & &1.is_published)
    next_open_slot = next_open_company_slot(slots)
    recent_metrics = recent_booking_metrics(user)

    %{
      services: length(services),
      resources: length(resources),
      slots: length(slots),
      open_slots: Enum.count(slots, &(&1.status == :available)),
      booked_slots: Enum.count(slots, &(&1.status == :booked)),
      pages: length(pages),
      published_pages: published_pages,
      draft_pages: length(pages) - published_pages,
      bookings: count_company_bookings(user),
      bookings_last_7_days: recent_metrics.bookings,
      revenue_last_7_days: recent_metrics.revenue,
      revenue_last_7_days_currency: recent_metrics.currency,
      next_open_slot: next_open_slot
    }
  end

  def recent_booking_pages(%User{} = user, limit \\ 5) when is_integer(limit) and limit > 0 do
    user
    |> list_booking_pages()
    |> Enum.take(limit)
  end

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
        |> validate_booking_status_capacity()
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

  def company_timezone(%BookingPage{} = page) do
    case page_company(page) do
      %Company{timezone: timezone} when is_binary(timezone) and timezone != "" -> timezone
      _ -> @default_company_timezone
    end
  end

  def page_local_datetime(%BookingPage{} = page, %DateTime{} = datetime) do
    shift_datetime_to_timezone(datetime, company_timezone(page))
  end

  def list_company_services(%User{} = user) do
    company_id = ensure_company!(user).id

    Repo.all(
      from(service in CompanyService,
        where: service.company_id == ^company_id,
        order_by: [asc: service.position, asc: service.name, desc: service.inserted_at]
      )
    )
  end

  def get_company_service(%User{} = user, id) when is_binary(id) do
    company_id = ensure_company!(user).id
    Repo.get_by(CompanyService, id: id, company_id: company_id)
  end

  def create_company_service(%User{} = user, attrs) when is_map(attrs) do
    company_id = ensure_company!(user).id

    %CompanyService{}
    |> CompanyService.changeset(put_company_id(attrs, company_id))
    |> Repo.insert()
  end

  def update_company_service(%CompanyService{} = service, attrs) when is_map(attrs) do
    service
    |> CompanyService.changeset(strip_id(attrs))
    |> Repo.update()
  end

  def delete_company_service(%CompanyService{} = service) do
    Repo.delete(service)
  end

  def change_company_service(%User{} = user, %CompanyService{} = service, attrs \\ %{}) do
    company_id =
      case service.id do
        nil -> ensure_company!(user).id
        _ -> service.company_id
      end

    CompanyService.changeset(service, put_company_id(attrs, company_id))
  end

  def list_company_resources(%User{} = user) do
    company_id = ensure_company!(user).id

    Repo.all(
      from(resource in CompanyResource,
        where: resource.company_id == ^company_id,
        order_by: [asc: resource.name, desc: resource.inserted_at]
      )
    )
  end

  def get_company_resource(%User{} = user, id) when is_binary(id) do
    company_id = ensure_company!(user).id
    Repo.get_by(CompanyResource, id: id, company_id: company_id)
  end

  def create_company_resource(%User{} = user, attrs) when is_map(attrs) do
    company_id = ensure_company!(user).id

    %CompanyResource{}
    |> CompanyResource.changeset(put_company_id(attrs, company_id))
    |> Repo.insert()
  end

  def update_company_resource(%CompanyResource{} = resource, attrs) when is_map(attrs) do
    resource
    |> CompanyResource.changeset(strip_id(attrs))
    |> Repo.update()
  end

  def delete_company_resource(%CompanyResource{} = resource) do
    Repo.delete(resource)
  end

  def change_company_resource(%User{} = user, %CompanyResource{} = resource, attrs \\ %{}) do
    company_id =
      case resource.id do
        nil -> ensure_company!(user).id
        _ -> resource.company_id
      end

    CompanyResource.changeset(resource, put_company_id(attrs, company_id))
  end

  def list_company_slots(%User{} = user) do
    company_id = ensure_company!(user).id

    Repo.all(
      from(slot in CompanySlot,
        left_join: service in assoc(slot, :service),
        left_join: resource in assoc(slot, :resource),
        left_join: booking_page in assoc(slot, :booking_page),
        where:
          slot.source_type == :manual and
            (is_nil(slot.service_id) or (not is_nil(service.id) and service.company_id == ^company_id)) and
            (is_nil(slot.resource_id) or (not is_nil(resource.id) and resource.company_id == ^company_id)),
        order_by: [desc: slot.start_time, desc: slot.inserted_at],
        preload: [service: service, resource: resource, booking_page: booking_page]
      )
    )
  end

  def get_company_slot(%User{} = user, id) when is_binary(id) do
    company_id = ensure_company!(user).id

    Repo.one(
      from(slot in CompanySlot,
        left_join: service in assoc(slot, :service),
        left_join: resource in assoc(slot, :resource),
        left_join: booking_page in assoc(slot, :booking_page),
        where: slot.id == ^id,
        where:
          (is_nil(slot.service_id) or (not is_nil(service.id) and service.company_id == ^company_id)) and
            (is_nil(slot.resource_id) or (not is_nil(resource.id) and resource.company_id == ^company_id)),
        preload: [service: service, resource: resource, booking_page: booking_page]
      )
    )
  end

  def create_company_slot(%User{} = user, attrs) when is_map(attrs) do
    normalized_attrs =
      attrs
      |> normalize_slot_attrs()
      |> apply_slot_page_targets(user)

    %CompanySlot{}
    |> CompanySlot.changeset(normalized_attrs)
    |> validate_slot_targets_owned_by_user(user)
    |> Repo.insert()
  end

  def update_company_slot(%User{} = user, %CompanySlot{} = slot, attrs) when is_map(attrs) do
    normalized_attrs =
      attrs
      |> normalize_slot_attrs()
      |> apply_slot_page_targets(user)

    slot
    |> CompanySlot.changeset(normalized_attrs)
    |> validate_slot_targets_owned_by_user(user)
    |> Repo.update()
  end

  def delete_company_slot(%CompanySlot{} = slot) do
    Repo.delete(slot)
  end

  def change_company_slot(%User{} = user, %CompanySlot{} = slot, attrs \\ %{}) do
    normalized_attrs =
      attrs
      |> normalize_slot_attrs()
      |> apply_slot_page_targets(user)

    slot
    |> CompanySlot.changeset(normalized_attrs)
    |> validate_slot_targets_owned_by_user(user)
  end

  def list_booking_pages(%User{} = user) do
    company_id = ensure_company!(user).id

    Repo.all(
      from(page in BookingPage,
        where: page.company_id == ^company_id,
        order_by: [desc: page.inserted_at],
        preload: [:service, :resource, :company]
      )
    )
  end

  def list_booking_pages_for_service(%User{} = user, service_id) when is_binary(service_id) do
    user
    |> list_booking_pages()
    |> Enum.filter(&(&1.service_id == service_id))
  end

  def list_booking_pages_for_resource(%User{} = user, resource_id) when is_binary(resource_id) do
    user
    |> list_booking_pages()
    |> Enum.filter(&(&1.resource_id == resource_id))
  end

  def get_booking_page(%User{} = user, id) when is_binary(id) do
    company_id = ensure_company!(user).id
    Repo.one(from(page in BookingPage, where: page.id == ^id and page.company_id == ^company_id, preload: [:service, :resource, :company]))
  end

  def create_booking_page_for_service(%User{} = user, service_id, attrs) when is_binary(service_id) and is_map(attrs) do
    case get_company_service(user, service_id) do
      %CompanyService{} ->
        company_id = ensure_company!(user).id

        %BookingPage{}
        |> BookingPage.changeset(
          attrs
          |> put_company_id(company_id)
          |> Map.put("service_id", service_id)
          |> Map.put("resource_id", nil)
          |> ensure_booking_page_slug()
        )
        |> Repo.insert()
        |> preload_page()

      _ ->
        {:error, :not_found}
    end
  end

  def create_booking_page_for_resource(%User{} = user, resource_id, attrs) when is_binary(resource_id) and is_map(attrs) do
    case get_company_resource(user, resource_id) do
      %CompanyResource{} ->
        company_id = ensure_company!(user).id

        %BookingPage{}
        |> BookingPage.changeset(
          attrs
          |> put_company_id(company_id)
          |> Map.put("service_id", nil)
          |> Map.put("resource_id", resource_id)
          |> ensure_booking_page_slug()
        )
        |> Repo.insert()
        |> preload_page()

      _ ->
        {:error, :not_found}
    end
  end

  def update_booking_page(%BookingPage{} = page, attrs) when is_map(attrs) do
    page
    |> BookingPage.changeset(
      page
      |> preserve_page_targets(attrs)
      |> ensure_booking_page_slug(page)
    )
    |> Repo.update()
    |> preload_page()
  end

  def delete_booking_page(%BookingPage{} = page) do
    Repo.delete(page)
  end

  def change_booking_page(user, parent_type, parent_id, page, attrs \\ %{})

  def change_booking_page(%User{} = user, parent_type, parent_id, %BookingPage{} = page, attrs) do
    company_id = ensure_company!(user).id

    BookingPage.changeset(page, attrs |> stringify_keys() |> Map.put("company_id", company_id) |> apply_parent_target(parent_type, parent_id))
  end

  def change_booking_page(%User{} = user, parent_type, parent_id, nil, attrs) do
    company_id = ensure_company!(user).id

    BookingPage.changeset(%BookingPage{}, attrs |> stringify_keys() |> Map.put("company_id", company_id) |> apply_parent_target(parent_type, parent_id))
  end

  def get_published_booking_page_by_slug(slug) when is_binary(slug) do
    Repo.one(from(page in BookingPage, where: page.slug == ^slug and page.is_published == true, preload: [:service, :resource, :company]))
  end

  def list_upcoming_slots_for_page(%BookingPage{} = page, day_count \\ 7) when is_integer(day_count) and day_count > 0 do
    {from_dt, to_dt} = booking_window(day_count)
    manual_slots = list_manual_slots_for_page(page, from_dt, to_dt)
    generated_slots = list_generated_slots_for_page(page, from_dt, to_dt)

    Enum.sort_by(manual_slots ++ generated_slots, &DateTime.to_unix(&1.start_time), :asc)
  end

  def create_booking_from_page(%BookingPage{} = page, attrs) when is_map(attrs) do
    slot_id = map_get(attrs, "slot_id")

    fn ->
      with {:ok, slot, booking_count} <- resolve_booking_slot(page, slot_id),
           {:ok, service} <- get_booking_service(slot),
           {:ok, resource} <- get_booking_resource(slot),
           :ok <- ensure_slot_matches_page(page, slot),
           {service, resource} <- scope_booking_targets(page, service, resource),
           {:ok, pricing} <- build_pricing(service, resource),
           {:ok, booking} <- insert_booking(slot, pricing, attrs) do
        maybe_close_full_slot(slot, booking_count + 1)
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

  def public_url(%BookingPage{slug: slug}) when is_binary(slug), do: "/book/#{slug}"

  def public_url(_page), do: nil

  defp count_company_bookings(%User{} = user) do
    Repo.aggregate(company_bookings_query(user), :count, :id)
  end

  defp recent_booking_metrics(%User{} = user) do
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

  defp next_open_company_slot(slots) do
    now = DateTime.utc_now()

    slots
    |> Enum.filter(fn slot ->
      slot.status == :available and
        match?(%DateTime{}, slot.start_time) and
        DateTime.compare(slot.start_time, now) in [:gt, :eq]
    end)
    |> Enum.min_by(&DateTime.to_unix(&1.start_time), fn -> nil end)
  end

  defp company_bookings_query(%User{} = user) do
    company_id = ensure_company!(user).id

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

  defp validate_slot_targets_owned_by_user(changeset, %User{} = user) do
    changeset
    |> validate_slot_service_belongs_to_user(user)
    |> validate_slot_resource_belongs_to_user(user)
    |> validate_slot_booking_page_belongs_to_user(user)
    |> validate_slot_matches_booking_page()
  end

  defp validate_slot_service_belongs_to_user(changeset, %User{} = user) do
    case Ecto.Changeset.get_field(changeset, :service_id) do
      nil ->
        changeset

      service_id ->
        if get_company_service(user, service_id) do
          changeset
        else
          Ecto.Changeset.add_error(changeset, :service_id, "must belong to your company")
        end
    end
  end

  defp validate_slot_resource_belongs_to_user(changeset, %User{} = user) do
    case Ecto.Changeset.get_field(changeset, :resource_id) do
      nil ->
        changeset

      resource_id ->
        if get_company_resource(user, resource_id) do
          changeset
        else
          Ecto.Changeset.add_error(changeset, :resource_id, "must belong to your company")
        end
    end
  end

  defp validate_slot_booking_page_belongs_to_user(changeset, %User{} = user) do
    case Ecto.Changeset.get_field(changeset, :booking_page_id) do
      nil ->
        changeset

      booking_page_id ->
        if get_booking_page(user, booking_page_id) do
          changeset
        else
          Ecto.Changeset.add_error(changeset, :booking_page_id, "must belong to your company")
        end
    end
  end

  defp validate_slot_matches_booking_page(changeset) do
    booking_page = Ecto.Changeset.get_field(changeset, :booking_page_id)
    service_id = Ecto.Changeset.get_field(changeset, :service_id)
    resource_id = Ecto.Changeset.get_field(changeset, :resource_id)

    case changeset.data do
      %CompanySlot{booking_page: %BookingPage{} = page} ->
        validate_slot_page_targets(changeset, page, service_id, resource_id)

      _ ->
        case booking_page && Repo.get(BookingPage, booking_page) do
          %BookingPage{} = page -> validate_slot_page_targets(changeset, page, service_id, resource_id)
          _ -> changeset
        end
    end
  end

  defp validate_slot_page_targets(changeset, %BookingPage{} = page, service_id, resource_id) do
    changeset
    |> maybe_add_target_mismatch(:service_id, page.service_id, service_id)
    |> maybe_add_target_mismatch(:resource_id, page.resource_id, resource_id)
  end

  defp maybe_add_target_mismatch(changeset, _field, nil, _value), do: changeset
  defp maybe_add_target_mismatch(changeset, _field, expected, expected), do: changeset

  defp maybe_add_target_mismatch(changeset, field, _expected, _value) do
    Ecto.Changeset.add_error(changeset, field, "must match the selected booking page target")
  end

  defp preserve_page_targets(%BookingPage{} = page, attrs) do
    attrs
    |> stringify_keys()
    |> Map.delete("id")
    |> Map.put("company_id", page.company_id)
    |> Map.put("service_id", page.service_id)
    |> Map.put("resource_id", page.resource_id)
  end

  defp ensure_booking_page_slug(attrs, page \\ nil) when is_map(attrs) do
    attrs = stringify_keys(attrs)
    existing_slug = existing_page_slug(page)

    case normalize_optional_slug(Map.get(attrs, "slug")) do
      slug when is_binary(slug) ->
        Map.put(attrs, "slug", slug)

      nil when is_binary(existing_slug) ->
        Map.put(attrs, "slug", existing_slug)

      _ ->
        Map.put(attrs, "slug", Ecto.UUID.generate())
    end
  end

  defp existing_page_slug(%BookingPage{slug: slug}) when is_binary(slug) and slug != "", do: slug
  defp existing_page_slug(_page), do: nil

  defp normalize_optional_slug(value) when is_binary(value) do
    value
    |> String.trim()
    |> String.downcase()
    |> case do
      "" -> nil
      normalized -> normalized
    end
  end

  defp normalize_optional_slug(_value), do: nil

  defp apply_parent_target(attrs, :service, service_id) when is_binary(service_id) do
    attrs
    |> Map.put("service_id", service_id)
    |> Map.put("resource_id", nil)
  end

  defp apply_parent_target(attrs, :resource, resource_id) when is_binary(resource_id) do
    attrs
    |> Map.put("service_id", nil)
    |> Map.put("resource_id", resource_id)
  end

  defp preload_page({:ok, %BookingPage{} = page}), do: {:ok, Repo.preload(page, [:service, :resource, :company])}
  defp preload_page(other), do: other

  defp list_manual_slots_for_page(%BookingPage{} = page, from_dt, to_dt) do
    slot_scope = manual_slot_scope(page)

    from(slot in CompanySlot,
      left_join: service in assoc(slot, :service),
      left_join: resource in assoc(slot, :resource),
      where: slot.source_type == :manual and slot.status == :available,
      where: slot.start_time >= ^from_dt and slot.start_time <= ^to_dt,
      where: ^slot_scope,
      order_by: [asc: slot.start_time],
      preload: [service: service, resource: resource]
    )
    |> Repo.all()
    |> Enum.map(&slot_to_view(page, &1, slot_booking_count(&1.id)))
    |> Enum.filter(&slot_open_for_booking?/1)
  end

  defp list_generated_slots_for_page(%BookingPage{} = page, from_dt, to_dt) do
    existing_slots =
      Repo.all(
        from(slot in CompanySlot,
          left_join: service in assoc(slot, :service),
          left_join: resource in assoc(slot, :resource),
          where:
            slot.source_type == :generated and slot.booking_page_id == ^page.id and
              slot.start_time >= ^from_dt and slot.start_time <= ^to_dt,
          order_by: [asc: slot.start_time],
          preload: [service: service, resource: resource]
        )
      )

    existing_by_window =
      Map.new(existing_slots, fn slot ->
        {generated_occurrence_key(slot.start_time, slot.end_time), slot}
      end)

    page
    |> build_auto_virtual_windows(from_dt, to_dt)
    |> Enum.map(fn %{start_time: start_time, end_time: end_time} = window ->
      case Map.get(existing_by_window, generated_occurrence_key(start_time, end_time)) do
        %CompanySlot{} = slot ->
          slot_to_view(page, slot, slot_booking_count(slot.id))

        nil ->
          window
          |> Map.put(:id, generated_virtual_slot_id(page.id, start_time, end_time))
          |> Map.put(:status, :available)
          |> Map.put(:service_id, page.service_id)
          |> Map.put(:resource_id, page.resource_id)
          |> Map.put(:source_type, :generated)
          |> Map.put(:max_bookings, page.default_max_bookings)
          |> Map.put(:booking_count, 0)
          |> Map.put(:remaining_capacity, remaining_capacity(page.default_max_bookings, 0))
          |> Map.put(:service_name, page.service && page.service.name)
          |> Map.put(:resource_name, page.resource && page.resource.name)
          |> Map.put(:service_price, if(keep_service_for_page?(page), do: page.service && page.service.price))
          |> Map.put(:resource_price, if(keep_resource_for_page?(page), do: page.resource && page.resource.price))
          |> Map.put(:currency, resolve_slot_currency(page.service && page.service.currency, page.resource && page.resource.currency))
      end
    end)
    |> Enum.filter(&slot_open_for_booking?/1)
  end

  defp build_auto_virtual_windows(%BookingPage{} = page, from_dt, to_dt) do
    with true <- page.auto_slots_enabled,
         %Date{} = schedule_start <- page.schedule_start_date,
         %Date{} = schedule_end <- page.schedule_end_date,
         %Time{} = work_start <- page.work_start_time,
         %Time{} = work_end <- page.work_end_time do
      timezone = company_timezone(page)
      range_start = max_date(schedule_start, DateTime.to_date(shift_datetime_to_timezone(from_dt, timezone)))
      range_end = min_date(schedule_end, DateTime.to_date(shift_datetime_to_timezone(to_dt, timezone)))

      if Date.before?(range_end, range_start) do
        []
      else
        weekdays = parse_available_weekdays(page.available_weekdays)
        excluded_dates = parse_excluded_dates(page.excluded_dates)

        range_start
        |> Date.range(range_end)
        |> Enum.flat_map(fn date ->
          if date_allowed_for_page?(date, weekdays, excluded_dates) do
            build_auto_windows_for_day(page, date, timezone, work_start, work_end, from_dt, to_dt)
          else
            []
          end
        end)
      end
    else
      _ -> []
    end
  end

  defp manual_slot_scope(%BookingPage{} = page) do
    global_scope =
      cond do
        is_binary(page.service_id) and is_binary(page.resource_id) ->
          dynamic([slot], is_nil(slot.booking_page_id) and slot.service_id == ^page.service_id and slot.resource_id == ^page.resource_id)

        is_binary(page.service_id) ->
          dynamic([slot], is_nil(slot.booking_page_id) and slot.service_id == ^page.service_id)

        is_binary(page.resource_id) ->
          dynamic([slot], is_nil(slot.booking_page_id) and slot.resource_id == ^page.resource_id)

        true ->
          dynamic([slot], false)
      end

    dynamic([slot], slot.booking_page_id == ^page.id or ^global_scope)
  end

  defp build_auto_windows_for_day(%BookingPage{} = page, date, timezone, work_start, work_end, from_dt, to_dt) do
    with {:ok, work_start_dt} <- build_local_datetime(date, work_start, timezone),
         {:ok, work_end_dt} <- build_local_datetime(date, work_end, timezone) do
      lunch_range = lunch_range_for_page(page, date, timezone)
      slot_minutes = page.slot_minutes || 60
      break_minutes = page.break_minutes || 0

      build_auto_windows_for_day(
        work_start_dt,
        work_end_dt,
        lunch_range,
        slot_minutes,
        break_minutes,
        from_dt,
        to_dt,
        []
      )
    else
      _ -> []
    end
  end

  defp build_auto_windows_for_day(current, work_end_dt, lunch_range, slot_minutes, break_minutes, from_dt, to_dt, acc) do
    slot_end = DateTime.add(current, slot_minutes * 60, :second)

    cond do
      DateTime.compare(current, work_end_dt) != :lt ->
        Enum.reverse(acc)

      DateTime.after?(slot_end, work_end_dt) ->
        Enum.reverse(acc)

      lunch_overlap?(lunch_range, current, slot_end) ->
        {_lunch_start, lunch_end} = lunch_range
        build_auto_windows_for_day(lunch_end, work_end_dt, lunch_range, slot_minutes, break_minutes, from_dt, to_dt, acc)

      DateTime.compare(slot_end, from_dt) in [:lt, :eq] ->
        next_start = DateTime.add(slot_end, break_minutes * 60, :second)
        build_auto_windows_for_day(next_start, work_end_dt, lunch_range, slot_minutes, break_minutes, from_dt, to_dt, acc)

      DateTime.after?(current, to_dt) ->
        Enum.reverse(acc)

      true ->
        next_start = DateTime.add(slot_end, break_minutes * 60, :second)

        build_auto_windows_for_day(
          next_start,
          work_end_dt,
          lunch_range,
          slot_minutes,
          break_minutes,
          from_dt,
          to_dt,
          [%{start_time: current, end_time: slot_end} | acc]
        )
    end
  end

  defp slot_to_view(page, %CompanySlot{} = slot, booking_count) do
    service = if Ecto.assoc_loaded?(slot.service), do: slot.service
    resource = if Ecto.assoc_loaded?(slot.resource), do: slot.resource
    service_currency = if(keep_service_for_page?(page), do: service && service.currency)
    resource_currency = if(keep_resource_for_page?(page), do: resource && resource.currency)

    %{
      id: slot.id,
      start_time: slot.start_time,
      end_time: slot.end_time,
      status: slot.status,
      service_id: slot.service_id,
      resource_id: slot.resource_id,
      source_type: slot.source_type,
      max_bookings: slot.max_bookings,
      booking_count: booking_count,
      remaining_capacity: remaining_capacity(slot.max_bookings, booking_count),
      service_name: if(keep_service_for_page?(page), do: service && service.name),
      resource_name: if(keep_resource_for_page?(page), do: resource && resource.name),
      service_price: if(keep_service_for_page?(page), do: service && service.price),
      resource_price: if(keep_resource_for_page?(page), do: resource && resource.price),
      currency: resolve_slot_currency(service_currency, resource_currency)
    }
  end

  defp booking_window(day_count) do
    from_dt = DateTime.utc_now()
    to_dt = DateTime.add(from_dt, day_count * @day_seconds, :second)
    {from_dt, to_dt}
  end

  defp resolve_booking_slot(_page, nil), do: {:error, :unavailable}

  defp resolve_booking_slot(%BookingPage{} = page, slot_id) do
    case Ecto.UUID.cast(slot_id) do
      {:ok, persisted_id} ->
        slot =
          CompanySlot
          |> where([slot], slot.id == ^persisted_id)
          |> maybe_lock_for_update()
          |> Repo.one()

        with {:ok, slot} <- ensure_slot_available(slot),
             booking_count = slot_booking_count(slot.id),
             :ok <- ensure_slot_has_capacity(slot, booking_count) do
          {:ok, Repo.preload(slot, [:service, :resource]), booking_count}
        end

      :error ->
        with {:ok, start_time, end_time} <- parse_generated_virtual_slot_id(page.id, slot_id),
             :ok <- ensure_virtual_slot_matches_page_schedule(page, start_time, end_time),
             {:ok, slot} <- get_or_create_generated_slot(page, start_time, end_time),
             {:ok, slot} <- ensure_slot_available(slot),
             booking_count = slot_booking_count(slot.id),
             :ok <- ensure_slot_has_capacity(slot, booking_count) do
          {:ok, Repo.preload(slot, [:service, :resource]), booking_count}
        end
    end
  end

  defp ensure_slot_available(nil), do: {:error, :unavailable}
  defp ensure_slot_available(%CompanySlot{status: :available} = slot), do: {:ok, slot}
  defp ensure_slot_available(_slot), do: {:error, :unavailable}

  defp ensure_slot_has_capacity(%CompanySlot{max_bookings: nil}, _booking_count), do: :ok

  defp ensure_slot_has_capacity(%CompanySlot{max_bookings: max_bookings}, booking_count) when is_integer(max_bookings) and booking_count < max_bookings, do: :ok

  defp ensure_slot_has_capacity(%CompanySlot{}, _booking_count), do: {:error, :slot_full}

  defp get_booking_service(%CompanySlot{service_id: nil}), do: {:ok, nil}

  defp get_booking_service(%CompanySlot{service_id: service_id}) do
    case Repo.get(CompanyService, service_id) do
      nil -> {:error, :slot_not_shareable}
      service -> {:ok, service}
    end
  end

  defp get_booking_resource(%CompanySlot{resource_id: nil}), do: {:ok, nil}

  defp get_booking_resource(%CompanySlot{resource_id: resource_id}) do
    case Repo.get(CompanyResource, resource_id) do
      nil -> {:error, :slot_not_shareable}
      resource -> {:ok, resource}
    end
  end

  defp ensure_slot_matches_page(page, slot) do
    with :ok <- ensure_target_match(page.service_id, slot.service_id) do
      ensure_target_match(page.resource_id, slot.resource_id)
    end
  end

  defp ensure_target_match(nil, _slot_target_id), do: :ok
  defp ensure_target_match(target_id, target_id), do: :ok
  defp ensure_target_match(_page_target_id, _slot_target_id), do: {:error, :slot_not_shareable}

  defp maybe_close_full_slot(%CompanySlot{max_bookings: nil}, _booking_count_after), do: :ok

  defp maybe_close_full_slot(%CompanySlot{} = slot, booking_count_after) do
    if is_integer(slot.max_bookings) and booking_count_after >= slot.max_bookings and slot.status == :available do
      Repo.update!(Ecto.Changeset.change(slot, status: :booked))
    end

    :ok
  end

  defp scope_booking_targets(page, service, resource) do
    {
      if(keep_service_for_page?(page), do: service),
      if(keep_resource_for_page?(page), do: resource)
    }
  end

  defp keep_service_for_page?(%BookingPage{service_id: service_id}) when is_binary(service_id), do: true
  defp keep_service_for_page?(%BookingPage{resource_id: resource_id}) when is_binary(resource_id), do: false
  defp keep_service_for_page?(_page), do: true

  defp keep_resource_for_page?(%BookingPage{resource_id: resource_id}) when is_binary(resource_id), do: true
  defp keep_resource_for_page?(%BookingPage{service_id: service_id}) when is_binary(service_id), do: false
  defp keep_resource_for_page?(_page), do: true

  defp build_pricing(service, resource) do
    service_price = money(service && service.price)
    resource_price = money(resource && resource.price)

    with {:ok, currency} <- resolve_currency(service, resource) do
      {:ok,
       %{
         service_id: service && service.id,
         resource_id: resource && resource.id,
         service_price: service_price,
         resource_price: resource_price,
         total_price: D.add(service_price, resource_price),
         currency: currency
       }}
    end
  end

  defp resolve_currency(nil, nil), do: {:ok, "KRW"}
  defp resolve_currency(%{currency: currency}, nil), do: {:ok, currency || "KRW"}
  defp resolve_currency(nil, %{currency: currency}), do: {:ok, currency || "KRW"}
  defp resolve_currency(%{currency: currency}, %{currency: currency}), do: {:ok, currency || "KRW"}
  defp resolve_currency(_service, _resource), do: {:error, :currency_mismatch}

  defp resolve_slot_currency(nil, nil), do: "KRW"
  defp resolve_slot_currency(currency, nil), do: currency || "KRW"
  defp resolve_slot_currency(nil, currency), do: currency || "KRW"
  defp resolve_slot_currency(currency, currency), do: currency || "KRW"
  defp resolve_slot_currency(_service_currency, _resource_currency), do: nil

  defp slot_booking_count(slot_id) do
    Repo.aggregate(from(booking in CompanyBooking, where: booking.slot_id == ^slot_id), :count, :id)
  end

  defp slot_open_for_booking?(%{status: status}) when status != :available, do: false
  defp slot_open_for_booking?(%{remaining_capacity: remaining_capacity}) when is_integer(remaining_capacity), do: remaining_capacity > 0
  defp slot_open_for_booking?(_slot), do: true

  defp remaining_capacity(nil, _booking_count), do: nil
  defp remaining_capacity(max_bookings, booking_count), do: max(max_bookings - booking_count, 0)

  defp generated_virtual_slot_id(page_id, start_time, end_time) do
    "virtual:#{page_id}:#{DateTime.to_unix(start_time)}:#{DateTime.to_unix(end_time)}"
  end

  defp parse_generated_virtual_slot_id(page_id, "virtual:" <> payload) do
    case String.split(payload, ":") do
      [^page_id, start_unix, end_unix] ->
        with {start_value, ""} <- Integer.parse(start_unix),
             {end_value, ""} <- Integer.parse(end_unix) do
          {:ok, DateTime.from_unix!(start_value), DateTime.from_unix!(end_value)}
        else
          _ -> {:error, :unavailable}
        end

      _ ->
        {:error, :unavailable}
    end
  end

  defp parse_generated_virtual_slot_id(_page_id, _slot_id), do: {:error, :unavailable}

  defp generated_occurrence_key(%DateTime{} = start_time, %DateTime{} = end_time) do
    "#{DateTime.to_unix(start_time)}:#{DateTime.to_unix(end_time)}"
  end

  defp ensure_virtual_slot_matches_page_schedule(%BookingPage{} = page, start_time, end_time) do
    page
    |> build_auto_virtual_windows(start_time, end_time)
    |> Enum.find(fn slot ->
      DateTime.compare(slot.start_time, start_time) == :eq and DateTime.compare(slot.end_time, end_time) == :eq
    end)
    |> case do
      nil -> {:error, :unavailable}
      _slot -> :ok
    end
  end

  defp get_or_create_generated_slot(%BookingPage{} = page, start_time, end_time) do
    case Repo.one(
           from(slot in CompanySlot,
             where:
               slot.booking_page_id == ^page.id and slot.source_type == :generated and
                 slot.start_time == ^start_time and slot.end_time == ^end_time
           )
         ) do
      %CompanySlot{} = slot ->
        {:ok, slot}

      nil ->
        attrs = %{
          "booking_page_id" => page.id,
          "source_type" => "generated",
          "max_bookings" => page.default_max_bookings,
          "start_time" => start_time,
          "end_time" => end_time,
          "status" => "available",
          "service_id" => page.service_id,
          "resource_id" => page.resource_id
        }

        %CompanySlot{}
        |> CompanySlot.changeset(attrs)
        |> Repo.insert()
        |> case do
          {:ok, slot} -> {:ok, slot}
          {:error, changeset} -> {:error, changeset}
        end
    end
  end

  defp max_date(left, right), do: if(Date.before?(left, right), do: right, else: left)
  defp min_date(left, right), do: if(Date.after?(left, right), do: right, else: left)

  defp parse_available_weekdays(value) do
    value
    |> to_string()
    |> String.split([",", "\n", " "], trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.map(&String.downcase/1)
    |> Enum.filter(&(&1 in ~w(mon tue wed thu fri sat sun)))
    |> MapSet.new()
  end

  defp parse_excluded_dates(value) do
    value
    |> to_string()
    |> String.split([",", "\n", " "], trim: true)
    |> Enum.reduce(MapSet.new(), fn entry, acc ->
      case Date.from_iso8601(String.trim(entry)) do
        {:ok, date} -> MapSet.put(acc, date)
        _ -> acc
      end
    end)
  end

  defp date_allowed_for_page?(date, weekdays, excluded_dates) do
    weekday_key = weekday_name(date)
    MapSet.member?(weekdays, weekday_key) and not MapSet.member?(excluded_dates, date)
  end

  defp lunch_range_for_page(%BookingPage{lunch_start_time: nil, lunch_end_time: nil}, _date, _timezone), do: nil

  defp lunch_range_for_page(%BookingPage{lunch_start_time: lunch_start, lunch_end_time: lunch_end}, date, timezone) when not is_nil(lunch_start) and not is_nil(lunch_end) do
    with {:ok, lunch_start_dt} <- build_local_datetime(date, lunch_start, timezone),
         {:ok, lunch_end_dt} <- build_local_datetime(date, lunch_end, timezone) do
      {lunch_start_dt, lunch_end_dt}
    else
      _ -> nil
    end
  end

  defp page_company(%BookingPage{company: company}) when is_struct(company, Company), do: company
  defp page_company(%BookingPage{company: company}) when company == nil, do: nil

  defp page_company(%BookingPage{} = page) do
    if Ecto.assoc_loaded?(page.company) do
      page.company
    else
      Repo.get(Company, page.company_id)
    end
  end

  defp shift_datetime_to_timezone(%DateTime{} = datetime, timezone) when is_binary(timezone) do
    offset_seconds = timezone_offset_seconds(timezone)
    shifted_datetime = DateTime.add(datetime, offset_seconds, :second)

    %{
      shifted_datetime
      | time_zone: timezone,
        zone_abbr: timezone_abbreviation(timezone),
        utc_offset: offset_seconds,
        std_offset: 0
    }
  end

  defp build_local_datetime(date, time, timezone) do
    offset_seconds = timezone_offset_seconds(timezone)
    naive_datetime = NaiveDateTime.new!(date, time)
    utc_naive_datetime = NaiveDateTime.add(naive_datetime, -offset_seconds, :second)
    {:ok, DateTime.from_naive!(utc_naive_datetime, "Etc/UTC")}
  end

  defp timezone_offset_seconds("Asia/Seoul"), do: 9 * 60 * 60
  defp timezone_offset_seconds("Asia/Tokyo"), do: 9 * 60 * 60
  defp timezone_offset_seconds("UTC"), do: 0
  defp timezone_offset_seconds("Etc/UTC"), do: 0

  defp timezone_offset_seconds(<<sign::binary-size(1), hours::binary-size(2), ":", minutes::binary-size(2)>>) when sign in ["+", "-"] do
    with {hour_value, ""} <- Integer.parse(hours),
         {minute_value, ""} <- Integer.parse(minutes) do
      multiplier = if sign == "-", do: -1, else: 1
      multiplier * (hour_value * 60 * 60 + minute_value * 60)
    else
      _ -> 0
    end
  end

  defp timezone_offset_seconds(_timezone), do: 0

  defp timezone_abbreviation("Asia/Seoul"), do: "KST"
  defp timezone_abbreviation("Asia/Tokyo"), do: "JST"
  defp timezone_abbreviation("UTC"), do: "UTC"
  defp timezone_abbreviation("Etc/UTC"), do: "UTC"
  defp timezone_abbreviation(timezone), do: timezone

  defp lunch_overlap?(nil, _start_time, _end_time), do: false

  defp lunch_overlap?({lunch_start, lunch_end}, start_time, end_time) do
    DateTime.before?(start_time, lunch_end) and DateTime.after?(end_time, lunch_start)
  end

  defp weekday_name(date) do
    case Date.day_of_week(date) do
      1 -> "mon"
      2 -> "tue"
      3 -> "wed"
      4 -> "thu"
      5 -> "fri"
      6 -> "sat"
      7 -> "sun"
    end
  end

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

  defp maybe_lock_for_update(query) do
    if Repo.__adapter__() == SQLite3 do
      query
    else
      lock(query, "FOR UPDATE")
    end
  end

  defp validate_booking_status_capacity(changeset) do
    slot_id = Ecto.Changeset.get_field(changeset, :slot_id)
    status = Ecto.Changeset.get_field(changeset, :status)
    booking_id = changeset.data && changeset.data.id

    cond do
      status != "confirmed" ->
        changeset

      is_nil(slot_id) ->
        changeset

      true ->
        case Repo.get(CompanySlot, slot_id) do
          nil ->
            Ecto.Changeset.add_error(changeset, :slot_id, "was not found")

          %CompanySlot{status: :cancelled} ->
            Ecto.Changeset.add_error(changeset, :status, "cannot confirm for a cancelled slot")

          %CompanySlot{} = slot when is_integer(slot.max_bookings) ->
            confirmed_count = confirmed_booking_count(slot_id, booking_id)

            if confirmed_count >= slot.max_bookings do
              Ecto.Changeset.add_error(changeset, :status, "slot has reached max bookings")
            else
              changeset
            end

          %CompanySlot{} ->
            changeset
        end
    end
  end

  defp confirmed_booking_count(slot_id, except_booking_id \\ nil) when is_binary(slot_id) do
    base_query =
      from(booking in CompanyBooking,
        where: booking.slot_id == ^slot_id and booking.status == "confirmed"
      )

    query =
      if is_binary(except_booking_id) do
        from(booking in base_query, where: booking.id != ^except_booking_id)
      else
        base_query
      end

    Repo.aggregate(query, :count, :id)
  end

  defp sync_slot_status_after_booking_update({:ok, booking}, slot_id) do
    sync_slot_status(slot_id)
    {:ok, booking}
  end

  defp sync_slot_status_after_booking_update(other, _slot_id), do: other

  defp sync_slot_status(slot_id) when is_binary(slot_id) do
    case Repo.get(CompanySlot, slot_id) do
      nil ->
        :ok

      %CompanySlot{status: :cancelled} ->
        :ok

      %CompanySlot{} = slot ->
        confirmed_count = confirmed_booking_count(slot_id)

        target_status =
          if is_integer(slot.max_bookings) and confirmed_count >= slot.max_bookings do
            :booked
          else
            :available
          end

        if slot.status != target_status do
          slot
          |> Ecto.Changeset.change(status: target_status)
          |> Repo.update()
        else
          :ok
        end
    end
  end

  defp sync_slot_status(_slot_id), do: :ok

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

  defp put_company_id(attrs, company_id) do
    attrs
    |> stringify_keys()
    |> Map.put("company_id", company_id)
  end

  defp strip_id(attrs) do
    attrs
    |> stringify_keys()
    |> Map.delete("id")
  end

  defp normalize_slot_attrs(attrs) do
    attrs
    |> stringify_keys()
    |> Map.delete("id")
    |> normalize_optional_id("service_id")
    |> normalize_optional_id("resource_id")
    |> normalize_optional_id("booking_page_id")
    |> normalize_optional_integer("max_bookings")
    |> normalize_datetime("start_time")
    |> normalize_datetime("end_time")
  end

  defp apply_slot_page_targets(attrs, %User{} = user) do
    case map_get(attrs, "booking_page_id") do
      nil ->
        attrs

      booking_page_id ->
        case get_booking_page(user, booking_page_id) do
          %BookingPage{} = page ->
            attrs
            |> maybe_put_page_target("service_id", page.service_id)
            |> maybe_put_page_target("resource_id", page.resource_id)

          _ ->
            attrs
        end
    end
  end

  defp maybe_put_page_target(attrs, _key, nil), do: attrs

  defp maybe_put_page_target(attrs, key, value) do
    case map_get(attrs, key) do
      nil -> Map.put(attrs, key, value)
      _ -> attrs
    end
  end

  defp normalize_optional_id(attrs, key) do
    if Map.has_key?(attrs, key) do
      Map.update!(attrs, key, &blank_to_nil/1)
    else
      attrs
    end
  end

  defp normalize_datetime(attrs, key) do
    if Map.has_key?(attrs, key) do
      Map.update!(attrs, key, &normalize_datetime_value/1)
    else
      attrs
    end
  end

  defp normalize_optional_integer(attrs, key) do
    if Map.has_key?(attrs, key) do
      Map.update!(attrs, key, &blank_to_integer/1)
    else
      attrs
    end
  end

  defp normalize_datetime_value(value) when value in [nil, ""], do: nil
  defp normalize_datetime_value(%DateTime{} = value), do: DateTime.truncate(value, :second)

  defp normalize_datetime_value(%NaiveDateTime{} = value) do
    value
    |> NaiveDateTime.truncate(:second)
    |> DateTime.from_naive!("Etc/UTC")
  end

  defp normalize_datetime_value(value) when is_binary(value) do
    value
    |> String.trim()
    |> case do
      "" ->
        nil

      trimmed ->
        trimmed
        |> ensure_seconds()
        |> parse_datetime()
    end
  end

  defp normalize_datetime_value(value), do: value

  defp ensure_seconds(<<value::binary-size(16)>>), do: value <> ":00"
  defp ensure_seconds(value), do: value

  defp parse_datetime(value) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _offset} ->
        DateTime.truncate(datetime, :second)

      _ ->
        case NaiveDateTime.from_iso8601(value) do
          {:ok, datetime} ->
            datetime
            |> NaiveDateTime.truncate(:second)
            |> DateTime.from_naive!("Etc/UTC")

          _ ->
            value
        end
    end
  end

  defp blank_to_nil(nil), do: nil
  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: value

  defp blank_to_integer(nil), do: nil
  defp blank_to_integer(""), do: nil

  defp blank_to_integer(value) when is_binary(value) do
    value
    |> String.trim()
    |> case do
      "" -> nil
      trimmed -> String.to_integer(trimmed)
    end
  rescue
    ArgumentError -> value
  end

  defp blank_to_integer(value), do: value

  defp company_login(%User{id: user_id}) do
    "company-#{String.replace(user_id, "-", "")}"
  end

  defp company_name(%User{name: name, email: email}) do
    cond do
      present?(name) -> "#{name} Company"
      present?(email) -> "#{email} Company"
      true -> "Company"
    end
  end

  defp money(nil), do: D.new(0)
  defp money(value), do: value

  defp map_get(map, key) do
    Map.get(map, key) || Map.get(map, String.to_existing_atom(key))
  rescue
    ArgumentError -> nil
  end

  defp stringify_keys(attrs) do
    Map.new(attrs, fn {key, value} -> {to_string(key), value} end)
  end

  defp present?(value), do: value not in [nil, ""]
end
