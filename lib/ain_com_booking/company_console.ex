defmodule AinComBooking.CompanyConsole do
  @moduledoc false

  import Ecto.Query, warn: false

  alias AinComBooking.Accounts.User
  alias AinComBooking.Bookings.CompanyBooking
  alias AinComBooking.Bookings.CompanySlot
  alias AinComBooking.Catalog.Company
  alias AinComBooking.Catalog.CompanyResource
  alias AinComBooking.Catalog.CompanyService
  alias AinComBooking.CompanyConsole.Bookings
  alias AinComBooking.CompanyConsole.Inventory
  alias AinComBooking.CompanyConsole.BookingPages
  alias AinComBooking.CompanyConsole.BookingPage
  alias AinComBooking.CompanyConsole.SlotGeneration
  alias AinComBooking.Repo

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
    pages = BookingPages.list_booking_pages(user)
    published_pages = Enum.count(pages, & &1.is_published)
    next_open_slot = next_open_company_slot(slots)
    recent_metrics = Bookings.recent_booking_metrics(user)

    %{
      services: length(services),
      resources: length(resources),
      slots: length(slots),
      open_slots: Enum.count(slots, &(&1.status == :available)),
      booked_slots: Enum.count(slots, &(&1.status == :booked)),
      pages: length(pages),
      published_pages: published_pages,
      draft_pages: length(pages) - published_pages,
      bookings: Bookings.count_company_bookings(user),
      bookings_last_7_days: recent_metrics.bookings,
      revenue_last_7_days: recent_metrics.revenue,
      revenue_last_7_days_currency: recent_metrics.currency,
      next_open_slot: next_open_slot
    }
  end

  def recent_booking_pages(%User{} = user, limit \\ 5) when is_integer(limit) and limit > 0 do
    BookingPages.recent_booking_pages(user, limit)
  end

  def list_company_bookings(%User{} = user) do
    Bookings.list_company_bookings(user)
  end

  def list_company_bookings_for_service(%User{} = user, service_id) when is_binary(service_id) do
    Bookings.list_company_bookings_for_service(user, service_id)
  end

  def list_company_bookings_for_resource(%User{} = user, resource_id) when is_binary(resource_id) do
    Bookings.list_company_bookings_for_resource(user, resource_id)
  end

  def confirmed_company_booking_counts_by_slot_ids(%User{} = user, slot_ids) when is_list(slot_ids) do
    Bookings.confirmed_company_booking_counts_by_slot_ids(user, slot_ids)
  end

  def get_company_booking(%User{} = user, id) when is_binary(id) do
    Bookings.get_company_booking(user, id)
  end

  def change_company_booking(%CompanyBooking{} = booking, attrs \\ %{}) do
    Bookings.change_company_booking(booking, attrs)
  end

  def update_company_booking(%User{} = user, %CompanyBooking{} = booking, attrs) when is_map(attrs) do
    Bookings.update_company_booking(user, booking, attrs)
  end

  def recent_company_bookings(%User{} = user, limit \\ 6) when is_integer(limit) and limit > 0 do
    Bookings.recent_company_bookings(user, limit)
  end

  def company_timezone(%BookingPage{} = page) do
    BookingPages.company_timezone(page)
  end

  def page_local_datetime(%BookingPage{} = page, %DateTime{} = datetime) do
    BookingPages.page_local_datetime(page, datetime)
  end

  def list_company_services(%User{} = user) do
    Inventory.list_company_services(user)
  end

  def get_company_service(%User{} = user, id) when is_binary(id) do
    Inventory.get_company_service(user, id)
  end

  def create_company_service(%User{} = user, attrs) when is_map(attrs) do
    Inventory.create_company_service(user, attrs)
  end

  def update_company_service(%CompanyService{} = service, attrs) when is_map(attrs) do
    Inventory.update_company_service(service, attrs)
  end

  def delete_company_service(%CompanyService{} = service) do
    Inventory.delete_company_service(service)
  end

  def change_company_service(%User{} = user, %CompanyService{} = service, attrs \\ %{}) do
    Inventory.change_company_service(user, service, attrs)
  end

  def list_company_resources(%User{} = user) do
    Inventory.list_company_resources(user)
  end

  def get_company_resource(%User{} = user, id) when is_binary(id) do
    Inventory.get_company_resource(user, id)
  end

  def create_company_resource(%User{} = user, attrs) when is_map(attrs) do
    Inventory.create_company_resource(user, attrs)
  end

  def update_company_resource(%CompanyResource{} = resource, attrs) when is_map(attrs) do
    Inventory.update_company_resource(resource, attrs)
  end

  def delete_company_resource(%CompanyResource{} = resource) do
    Inventory.delete_company_resource(resource)
  end

  def change_company_resource(%User{} = user, %CompanyResource{} = resource, attrs \\ %{}) do
    Inventory.change_company_resource(user, resource, attrs)
  end

  def list_company_slots(%User{} = user) do
    SlotGeneration.list_company_slots(user)
  end

  def get_company_slot(%User{} = user, id) when is_binary(id) do
    SlotGeneration.get_company_slot(user, id)
  end

  def create_company_slot(%User{} = user, attrs) when is_map(attrs) do
    SlotGeneration.create_company_slot(user, attrs)
  end

  def update_company_slot(%User{} = user, %CompanySlot{} = slot, attrs) when is_map(attrs) do
    SlotGeneration.update_company_slot(user, slot, attrs)
  end

  def delete_company_slot(%CompanySlot{} = slot) do
    SlotGeneration.delete_company_slot(slot)
  end

  def change_company_slot(%User{} = user, %CompanySlot{} = slot, attrs \\ %{}) do
    SlotGeneration.change_company_slot(user, slot, attrs)
  end

  def list_booking_pages(%User{} = user) do
    BookingPages.list_booking_pages(user)
  end

  def list_booking_pages_for_service(%User{} = user, service_id) when is_binary(service_id) do
    BookingPages.list_booking_pages_for_service(user, service_id)
  end

  def list_booking_pages_for_resource(%User{} = user, resource_id) when is_binary(resource_id) do
    BookingPages.list_booking_pages_for_resource(user, resource_id)
  end

  def get_booking_page(%User{} = user, id) when is_binary(id) do
    BookingPages.get_booking_page(user, id)
  end

  def create_booking_page_for_service(%User{} = user, service_id, attrs) when is_binary(service_id) and is_map(attrs) do
    BookingPages.create_booking_page_for_service(user, service_id, attrs)
  end

  def create_booking_page_for_resource(%User{} = user, resource_id, attrs) when is_binary(resource_id) and is_map(attrs) do
    BookingPages.create_booking_page_for_resource(user, resource_id, attrs)
  end

  def update_booking_page(%BookingPage{} = page, attrs) when is_map(attrs) do
    BookingPages.update_booking_page(page, attrs)
  end

  def delete_booking_page(%BookingPage{} = page) do
    BookingPages.delete_booking_page(page)
  end

  def change_booking_page(user, parent_type, parent_id, page, attrs \\ %{})

  def change_booking_page(%User{} = user, parent_type, parent_id, %BookingPage{} = page, attrs) do
    BookingPages.change_booking_page(user, parent_type, parent_id, page, attrs)
  end

  def change_booking_page(%User{} = user, parent_type, parent_id, nil, attrs) do
    BookingPages.change_booking_page(user, parent_type, parent_id, nil, attrs)
  end

  def get_published_booking_page_by_slug(slug) when is_binary(slug) do
    BookingPages.get_published_booking_page_by_slug(slug)
  end

  def list_upcoming_slots_for_page(%BookingPage{} = page, day_count \\ 7) when is_integer(day_count) and day_count > 0 do
    SlotGeneration.list_upcoming_slots_for_page(page, day_count)
  end

  def create_booking_from_page(%BookingPage{} = page, attrs) when is_map(attrs) do
    Bookings.create_booking_from_page(page, attrs)
  end

  def booking_error_message(reason), do: Bookings.booking_error_message(reason)

  def public_url(%BookingPage{} = page), do: BookingPages.public_url(page)
  def public_url(_page), do: nil

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

  defp present?(value), do: value not in [nil, ""]
end
