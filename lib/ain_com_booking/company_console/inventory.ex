defmodule AinComBooking.CompanyConsole.Inventory do
  @moduledoc false

  import Ecto.Query, warn: false

  alias AinComBooking.Accounts.User
  alias AinComBooking.Catalog.CompanyResource
  alias AinComBooking.Catalog.CompanyService
  alias AinComBooking.CompanyConsole
  alias AinComBooking.Repo

  def list_company_services(%User{} = user) do
    company_id = CompanyConsole.ensure_company!(user).id

    Repo.all(
      from(service in CompanyService,
        where: service.company_id == ^company_id,
        order_by: [asc: service.position, asc: service.name, desc: service.inserted_at]
      )
    )
  end

  def get_company_service(%User{} = user, id) when is_binary(id) do
    company_id = CompanyConsole.ensure_company!(user).id
    Repo.get_by(CompanyService, id: id, company_id: company_id)
  end

  def create_company_service(%User{} = user, attrs) when is_map(attrs) do
    company_id = CompanyConsole.ensure_company!(user).id

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
        nil -> CompanyConsole.ensure_company!(user).id
        _ -> service.company_id
      end

    CompanyService.changeset(service, put_company_id(attrs, company_id))
  end

  def list_company_resources(%User{} = user) do
    company_id = CompanyConsole.ensure_company!(user).id

    Repo.all(
      from(resource in CompanyResource,
        where: resource.company_id == ^company_id,
        order_by: [asc: resource.name, desc: resource.inserted_at]
      )
    )
  end

  def get_company_resource(%User{} = user, id) when is_binary(id) do
    company_id = CompanyConsole.ensure_company!(user).id
    Repo.get_by(CompanyResource, id: id, company_id: company_id)
  end

  def create_company_resource(%User{} = user, attrs) when is_map(attrs) do
    company_id = CompanyConsole.ensure_company!(user).id

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
        nil -> CompanyConsole.ensure_company!(user).id
        _ -> resource.company_id
      end

    CompanyResource.changeset(resource, put_company_id(attrs, company_id))
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

  defp stringify_keys(attrs) do
    Map.new(attrs, fn {key, value} -> {to_string(key), value} end)
  end
end
