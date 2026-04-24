defmodule AinComBooking.CompanyConsole.BookingPages do
  @moduledoc false

  import Ecto.Query, warn: false

  alias AinComBooking.Accounts.User
  alias AinComBooking.Catalog.Company
  alias AinComBooking.Catalog.CompanyResource
  alias AinComBooking.Catalog.CompanyService
  alias AinComBooking.CompanyConsole
  alias AinComBooking.CompanyConsole.BookingPage
  alias AinComBooking.CompanyConsole.Inventory
  alias AinComBooking.Repo

  @default_company_timezone "Asia/Seoul"

  def list_booking_pages(%User{} = user) do
    company_id = CompanyConsole.ensure_company!(user).id

    Repo.all(
      from(page in BookingPage,
        where: page.company_id == ^company_id,
        order_by: [desc: page.inserted_at],
        preload: [:service, :resource, :company]
      )
    )
  end

  def recent_booking_pages(%User{} = user, limit \\ 5) when is_integer(limit) and limit > 0 do
    user
    |> list_booking_pages()
    |> Enum.take(limit)
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
    company_id = CompanyConsole.ensure_company!(user).id

    Repo.one(
      from(page in BookingPage,
        where: page.id == ^id and page.company_id == ^company_id,
        preload: [:service, :resource, :company]
      )
    )
  end

  def create_booking_page_for_service(%User{} = user, service_id, attrs) when is_binary(service_id) and is_map(attrs) do
    case Inventory.get_company_service(user, service_id) do
      %CompanyService{} ->
        company_id = CompanyConsole.ensure_company!(user).id

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
    case Inventory.get_company_resource(user, resource_id) do
      %CompanyResource{} ->
        company_id = CompanyConsole.ensure_company!(user).id

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
    company_id = CompanyConsole.ensure_company!(user).id

    BookingPage.changeset(
      page,
      attrs
      |> stringify_keys()
      |> Map.put("company_id", company_id)
      |> apply_parent_target(parent_type, parent_id)
    )
  end

  def change_booking_page(%User{} = user, parent_type, parent_id, nil, attrs) do
    company_id = CompanyConsole.ensure_company!(user).id

    BookingPage.changeset(
      %BookingPage{},
      attrs
      |> stringify_keys()
      |> Map.put("company_id", company_id)
      |> apply_parent_target(parent_type, parent_id)
    )
  end

  def get_published_booking_page_by_slug(slug) when is_binary(slug) do
    Repo.one(
      from(page in BookingPage,
        where: page.slug == ^slug and page.is_published == true,
        preload: [:service, :resource, :company]
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

  def public_url(%BookingPage{slug: slug}) when is_binary(slug), do: "/book/#{slug}"
  def public_url(_page), do: nil

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

  defp put_company_id(attrs, company_id) when is_map(attrs) do
    attrs
    |> stringify_keys()
    |> Map.put("company_id", company_id)
  end

  defp stringify_keys(attrs) when is_map(attrs) do
    Map.new(attrs, fn {key, value} -> {to_string(key), value} end)
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
end
