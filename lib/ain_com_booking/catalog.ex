defmodule AinComBooking.Catalog do
  @moduledoc false

  import Ecto.Query, warn: false

  alias AinComBooking.Accounts.User
  alias AinComBooking.Bookings.UserSlot
  alias AinComBooking.Catalog.UserResource
  alias AinComBooking.Catalog.UserService
  alias AinComBooking.Repo

  def list_user_services(%User{id: user_id}) do
    Repo.all(
      from(service in UserService,
        where: service.user_id == ^user_id,
        order_by: [asc: service.position, desc: service.inserted_at]
      )
    )
  end

  def get_user_service(%User{id: user_id}, id) when is_binary(id) do
    Repo.one(
      from(service in UserService,
        where: service.id == ^id and service.user_id == ^user_id
      )
    )
  end

  def create_user_service(%User{} = user, attrs) when is_map(attrs) do
    %UserService{}
    |> UserService.changeset(put_user_id(attrs, user.id))
    |> Repo.insert()
  end

  def update_user_service(%UserService{} = service, attrs) when is_map(attrs) do
    service
    |> UserService.changeset(Map.delete(attrs, "id"))
    |> Repo.update()
  end

  def delete_user_service(%UserService{} = service) do
    Repo.delete(service)
  end

  def change_user_service(%User{} = user, %UserService{} = service, attrs \\ %{}) do
    service_owner_id =
      case service.id do
        nil -> user.id
        _ -> service.user_id
      end

    UserService.changeset(service, put_user_id(attrs, service_owner_id))
  end

  def list_user_resources(%User{id: user_id}) do
    Repo.all(
      from(resource in UserResource,
        where: resource.user_id == ^user_id,
        order_by: [desc: resource.inserted_at]
      )
    )
  end

  def get_user_resource(%User{id: user_id}, id) when is_binary(id) do
    Repo.get_by(UserResource, id: id, user_id: user_id)
  end

  def create_user_resource(%User{} = user, attrs) when is_map(attrs) do
    %UserResource{}
    |> UserResource.changeset(put_user_id(attrs, user.id))
    |> Repo.insert()
  end

  def update_user_resource(%UserResource{} = resource, attrs) when is_map(attrs) do
    resource
    |> UserResource.changeset(Map.delete(attrs, "id"))
    |> Repo.update()
  end

  def delete_user_resource(%UserResource{} = resource) do
    Repo.delete(resource)
  end

  def change_user_resource(%User{} = user, %UserResource{} = resource, attrs \\ %{}) do
    UserResource.changeset(resource, put_user_id(attrs, user.id))
  end

  def list_user_slots(%User{} = user) do
    Repo.all(
      from(slot in UserSlot,
        left_join: service in assoc(slot, :service),
        left_join: resource in assoc(slot, :resource),
        where:
          (is_nil(slot.service_id) or (not is_nil(service.id) and service.user_id == ^user.id)) and
            (is_nil(slot.resource_id) or (not is_nil(resource.id) and resource.user_id == ^user.id)),
        order_by: [desc: slot.start_time, desc: slot.inserted_at],
        preload: [service: service, resource: resource]
      )
    )
  end

  def get_user_slot(%User{} = user, id) when is_binary(id) do
    Repo.one(
      from(slot in UserSlot,
        left_join: service in assoc(slot, :service),
        left_join: resource in assoc(slot, :resource),
        where: slot.id == ^id,
        where:
          (is_nil(slot.service_id) or (not is_nil(service.id) and service.user_id == ^user.id)) and
            (is_nil(slot.resource_id) or (not is_nil(resource.id) and resource.user_id == ^user.id)),
        preload: [service: service, resource: resource]
      )
    )
  end

  def create_user_slot(%User{} = user, attrs) when is_map(attrs) do
    %UserSlot{}
    |> UserSlot.changeset(normalize_slot_attrs(attrs))
    |> validate_slot_targets_owned_by_user(user)
    |> Repo.insert()
  end

  def update_user_slot(%User{} = user, %UserSlot{} = slot, attrs) when is_map(attrs) do
    slot
    |> UserSlot.changeset(normalize_slot_attrs(attrs))
    |> validate_slot_targets_owned_by_user(user)
    |> Repo.update()
  end

  def delete_user_slot(%UserSlot{} = slot) do
    Repo.delete(slot)
  end

  def change_user_slot(%User{} = user, %UserSlot{} = slot, attrs \\ %{}) do
    slot
    |> UserSlot.changeset(normalize_slot_attrs(attrs))
    |> validate_slot_targets_owned_by_user(user)
  end

  defp put_user_id(attrs, user_id) do
    attrs
    |> stringify_keys()
    |> Map.put("user_id", user_id)
  end

  defp validate_slot_targets_owned_by_user(changeset, %User{} = user) do
    changeset
    |> validate_slot_service_belongs_to_user(user)
    |> validate_slot_resource_belongs_to_user(user)
  end

  defp validate_slot_service_belongs_to_user(changeset, %User{} = user) do
    case Ecto.Changeset.get_field(changeset, :service_id) do
      nil ->
        changeset

      service_id ->
        if get_user_service(user, service_id) do
          changeset
        else
          Ecto.Changeset.add_error(changeset, :service_id, "must belong to you")
        end
    end
  end

  defp validate_slot_resource_belongs_to_user(changeset, %User{} = user) do
    case Ecto.Changeset.get_field(changeset, :resource_id) do
      nil ->
        changeset

      resource_id ->
        if get_user_resource(user, resource_id) do
          changeset
        else
          Ecto.Changeset.add_error(changeset, :resource_id, "must belong to you")
        end
    end
  end

  defp normalize_slot_attrs(attrs) do
    attrs
    |> stringify_keys()
    |> Map.delete("id")
    |> normalize_optional_id("service_id")
    |> normalize_optional_id("resource_id")
    |> normalize_datetime("start_time")
    |> normalize_datetime("end_time")
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

  defp stringify_keys(attrs) do
    Map.new(attrs, fn {key, value} -> {to_string(key), value} end)
  end
end
