defmodule AinComBooking.Social do
  @moduledoc false
  import Ecto.Query, warn: false

  alias AinComBooking.Accounts.Follow
  alias AinComBooking.Accounts.User
  alias AinComBooking.Bookings.UserBooking
  alias AinComBooking.Bookings.UserSlot
  alias AinComBooking.Catalog.UserResource
  alias AinComBooking.Catalog.UserService
  alias AinComBooking.Repo
  alias AinComBooking.Social.Post
  alias Decimal, as: D

  @day_seconds 24 * 60 * 60
  @default_post_timezone "Asia/Seoul"

  @doc """
  Returns users visible in the social feed for the given viewer.

  Visibility rules:
  - `public`: visible to everyone
  - `followers`: visible only to followers of the target user
  - `link` and `private`: excluded from feed
  """
  def list_feed_users(%User{id: viewer_id}) when is_binary(viewer_id) do
    list_feed_users(viewer_id)
  end

  def list_feed_users(viewer_id) when is_binary(viewer_id) do
    Repo.all(
      from(u in User,
        left_join: f in Follow,
        on: f.followed_id == u.id and f.follower_id == ^viewer_id,
        where: u.id != ^viewer_id,
        where: u.feed_visibility == :public or (u.feed_visibility == :followers and not is_nil(f.follower_id)),
        order_by: [desc: u.inserted_at]
      )
    )
  end

  def list_suggested_users(viewer_or_id, limit \\ 5)

  def list_suggested_users(%User{id: viewer_id}, limit) when is_binary(viewer_id) do
    list_suggested_users(viewer_id, limit)
  end

  def list_suggested_users(viewer_id, limit) when is_binary(viewer_id) and is_integer(limit) and limit > 0 do
    fetch_count = max(limit * 3, limit)

    from(u in User,
      left_join: f in Follow,
      on: f.followed_id == u.id and f.follower_id == ^viewer_id,
      left_join: p in Post,
      on: p.user_id == u.id and p.visibility == :public,
      where: u.id != ^viewer_id,
      where: u.feed_visibility in [:public, :followers],
      group_by: [u.id, f.follower_id],
      order_by: [desc: count(p.id, :distinct), desc: u.inserted_at],
      limit: ^fetch_count,
      select: %{
        id: u.id,
        name: u.name,
        feed_visibility: u.feed_visibility,
        following: not is_nil(f.follower_id),
        public_share_count: count(p.id, :distinct)
      }
    )
    |> Repo.all()
    |> Enum.sort_by(fn user -> {user.following, -user.public_share_count, user.name || ""} end)
    |> Enum.take(limit)
  end

  def change_post(%User{id: user_id}, attrs \\ %{}) when is_binary(user_id) do
    %Post{}
    |> Post.changeset(with_owner(attrs, user_id))
    |> validate_post_targets_owned_by_user(user_id)
  end

  def create_post(%User{id: user_id} = user, attrs) when is_binary(user_id) do
    user
    |> change_post(attrs)
    |> Repo.insert()
    |> case do
      {:ok, post} -> {:ok, Repo.preload(post, [:user, :service, :resource])}
      {:error, changeset} -> {:error, changeset}
    end
  end

  def list_feed_posts(%User{id: viewer_id}) when is_binary(viewer_id) do
    list_feed_posts(viewer_id)
  end

  def list_feed_posts(viewer_id) when is_binary(viewer_id) do
    list_feed_posts(viewer_id, :home)
  end

  def list_feed_posts(%User{id: viewer_id}, scope) when is_binary(viewer_id) do
    list_feed_posts(viewer_id, scope)
  end

  def list_feed_posts(viewer_id, scope) when is_binary(viewer_id) and scope in [:home, :following, :mine] do
    viewer_id
    |> feed_posts_query(scope)
    |> Repo.all()
    |> Repo.preload([:service, :resource])
  end

  def list_profile_posts(viewer, profile_user, limit \\ 3)

  def list_profile_posts(%User{id: viewer_id}, %User{id: profile_user_id}, limit) when is_binary(viewer_id) and is_binary(profile_user_id) do
    list_profile_posts(viewer_id, profile_user_id, limit)
  end

  def list_profile_posts(viewer_id, profile_user_id, limit) when is_binary(viewer_id) and is_binary(profile_user_id) and is_integer(limit) and limit > 0 do
    viewer_id
    |> feed_posts_query()
    |> where([post, _user, _follow], post.user_id == ^profile_user_id)
    |> limit(^limit)
    |> Repo.all()
    |> Repo.preload([:service, :resource])
  end

  def list_booking_activity(%User{id: viewer_id}) when is_binary(viewer_id) do
    list_booking_activity(viewer_id)
  end

  def list_booking_activity(viewer_id) when is_binary(viewer_id) do
    Repo.all(
      from(booking in UserBooking,
        left_join: slot in assoc(booking, :slot),
        left_join: service in assoc(booking, :service),
        left_join: resource in assoc(booking, :resource),
        where: booking.user_id == ^viewer_id,
        order_by: [desc: booking.inserted_at],
        select: %{
          id: booking.id,
          inserted_at: booking.inserted_at,
          status: booking.status,
          customer_name: booking.customer_name,
          total_price: booking.total_price,
          currency: booking.currency,
          start_time: slot.start_time,
          end_time: slot.end_time,
          service_name: service.name,
          resource_name: resource.name
        }
      )
    )
  end

  def get_visible_post(%User{id: viewer_id}, post_id) when is_binary(post_id) do
    get_visible_post(viewer_id, post_id)
  end

  def get_visible_post(viewer_id, post_id) when is_binary(viewer_id) and is_binary(post_id) do
    viewer_id
    |> feed_posts_query()
    |> where([post, _user, _follow], post.id == ^post_id)
    |> Repo.one()
    |> case do
      nil -> nil
      post -> Repo.preload(post, [:service, :resource])
    end
  end

  def get_public_post(post_id) when is_binary(post_id) do
    Repo.one(from(post in Post, where: post.id == ^post_id and post.visibility == :public, preload: [:user, :service, :resource]))
  end

  def list_share_targets(%User{id: user_id}) when is_binary(user_id) do
    upcoming_slot_counts = upcoming_slot_counts()

    %{
      services: list_user_services(user_id, upcoming_slot_counts.service_counts),
      resources: list_user_resources(user_id, upcoming_slot_counts.resource_counts)
    }
  end

  def list_weekly_slots_for_post(%Post{} = post) do
    list_upcoming_slots_for_post(post, 7)
  end

  def list_upcoming_slots_for_post(%Post{} = post, day_count) when is_integer(day_count) and day_count > 0 do
    {from_dt, to_dt} = booking_window(day_count)
    manual_slots = list_manual_slots_for_post(post, from_dt, to_dt)
    generated_slots = list_generated_slots_for_post(post, from_dt, to_dt)

    Enum.sort_by(manual_slots ++ generated_slots, &DateTime.to_unix(&1.start_time), :asc)
  end

  def create_booking_from_post(%Post{} = post, attrs) when is_map(attrs) do
    slot_id = map_get(attrs, "slot_id")

    fn ->
      with {:ok, slot, booking_count} <- resolve_booking_slot(post, slot_id),
           {:ok, service} <- get_booking_service(slot),
           {:ok, resource} <- get_booking_resource(slot),
           :ok <- ensure_slot_owned_by_post_owner(post, service, resource),
           :ok <- ensure_slot_matches_post(post, slot),
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

  def feed_visibility_options do
    [
      {"Public", "public"},
      {"Followers", "followers"},
      {"Private", "private"}
    ]
  end

  def booking_error_message(:unavailable), do: "That slot is no longer available."
  def booking_error_message(:slot_full), do: "That slot has reached its booking limit."
  def booking_error_message(:slot_not_shareable), do: "That slot is not part of this shared availability."
  def booking_error_message(:currency_mismatch), do: "This slot has inconsistent pricing data."
  def booking_error_message(%Ecto.Changeset{}), do: "Please complete the booking form."
  def booking_error_message(_), do: "Booking could not be completed."

  def post_timezone(%Post{timezone: timezone}) when is_binary(timezone) and timezone != "", do: timezone
  def post_timezone(_post), do: @default_post_timezone

  def post_local_datetime(post, %DateTime{} = datetime) do
    shift_datetime_to_timezone(datetime, post_timezone(post))
  end

  defp feed_posts_query(viewer_id), do: feed_posts_query(viewer_id, :home)

  defp feed_posts_query(viewer_id, :home) do
    from(post in Post,
      join: user in assoc(post, :user),
      left_join: follow in Follow,
      on: follow.followed_id == post.user_id and follow.follower_id == ^viewer_id,
      where:
        post.user_id == ^viewer_id or
          post.visibility == :public or
          (post.visibility == :followers and not is_nil(follow.follower_id)),
      order_by: [desc: post.inserted_at],
      preload: [user: user]
    )
  end

  defp feed_posts_query(viewer_id, :following) do
    from(post in Post,
      join: user in assoc(post, :user),
      join: follow in Follow,
      on: follow.followed_id == post.user_id and follow.follower_id == ^viewer_id,
      where: post.visibility in [:public, :followers],
      order_by: [desc: post.inserted_at],
      preload: [user: user]
    )
  end

  defp feed_posts_query(viewer_id, :mine) do
    from(post in Post,
      join: user in assoc(post, :user),
      where: post.user_id == ^viewer_id,
      order_by: [desc: post.inserted_at],
      preload: [user: user]
    )
  end

  defp with_owner(attrs, user_id) do
    attrs
    |> stringify_keys()
    |> Map.put("user_id", user_id)
  end

  defp validate_post_targets_owned_by_user(changeset, user_id) do
    changeset
    |> validate_owned_service(user_id)
    |> validate_owned_resource(user_id)
  end

  defp validate_owned_service(changeset, user_id) do
    case Ecto.Changeset.get_field(changeset, :service_id) do
      nil ->
        changeset

      service_id ->
        if Repo.exists?(from(service in UserService, where: service.id == ^service_id and service.user_id == ^user_id)) do
          changeset
        else
          Ecto.Changeset.add_error(changeset, :service_id, "must belong to the author")
        end
    end
  end

  defp validate_owned_resource(changeset, user_id) do
    case Ecto.Changeset.get_field(changeset, :resource_id) do
      nil ->
        changeset

      resource_id ->
        if Repo.exists?(from(resource in UserResource, where: resource.id == ^resource_id and resource.user_id == ^user_id)) do
          changeset
        else
          Ecto.Changeset.add_error(changeset, :resource_id, "must belong to the author")
        end
    end
  end

  defp upcoming_slot_counts do
    now = DateTime.utc_now()

    service_counts =
      from(slot in UserSlot,
        where: slot.status == :available and slot.start_time >= ^now and not is_nil(slot.service_id),
        group_by: slot.service_id,
        select: {slot.service_id, count(slot.id)}
      )
      |> Repo.all()
      |> Map.new()

    resource_counts =
      from(slot in UserSlot,
        where: slot.status == :available and slot.start_time >= ^now and not is_nil(slot.resource_id),
        group_by: slot.resource_id,
        select: {slot.resource_id, count(slot.id)}
      )
      |> Repo.all()
      |> Map.new()

    %{service_counts: service_counts, resource_counts: resource_counts}
  end

  defp list_user_services(user_id, counts) do
    from(service in UserService,
      where: service.user_id == ^user_id,
      order_by: [asc: service.name]
    )
    |> Repo.all()
    |> Enum.map(fn service ->
      %{
        id: service.id,
        name: service.name,
        price: service.price,
        currency: service.currency,
        description: first_present(service.description_text, service.description_html),
        slot_count: Map.get(counts, service.id, 0)
      }
    end)
  end

  defp list_user_resources(user_id, counts) do
    from(resource in UserResource,
      where: resource.user_id == ^user_id,
      order_by: [asc: resource.name]
    )
    |> Repo.all()
    |> Enum.map(fn resource ->
      %{
        id: resource.id,
        name: resource.name,
        price: resource.price,
        currency: resource.currency,
        description: first_present(resource.location, resource.description),
        slot_count: Map.get(counts, resource.id, 0)
      }
    end)
  end

  defp booking_window(day_count) when is_integer(day_count) and day_count > 0 do
    from_dt = DateTime.utc_now()
    to_dt = DateTime.add(from_dt, day_count * @day_seconds, :second)
    {from_dt, to_dt}
  end

  defp list_manual_slots_for_post(%Post{} = post, from_dt, to_dt) do
    slot_scope = manual_slot_scope(post)

    from(slot in UserSlot,
      left_join: service in assoc(slot, :service),
      left_join: resource in assoc(slot, :resource),
      where: slot.source_type == :manual and slot.status == :available,
      where: slot.start_time >= ^from_dt and slot.start_time <= ^to_dt,
      where:
        (is_nil(slot.service_id) or (not is_nil(service.id) and service.user_id == ^post.user_id)) and
          (is_nil(slot.resource_id) or (not is_nil(resource.id) and resource.user_id == ^post.user_id)),
      where: ^slot_scope,
      order_by: [asc: slot.start_time],
      preload: [service: service, resource: resource]
    )
    |> Repo.all()
    |> Enum.map(&slot_to_view(post, &1, slot_booking_count(&1.id)))
    |> Enum.filter(&slot_open_for_booking?/1)
  end

  defp list_generated_slots_for_post(%Post{} = post, from_dt, to_dt) do
    existing_slots =
      Repo.all(
        from(slot in UserSlot,
          left_join: service in assoc(slot, :service),
          left_join: resource in assoc(slot, :resource),
          where:
            slot.source_type == :generated and slot.post_id == ^post.id and
              slot.start_time >= ^from_dt and slot.start_time <= ^to_dt,
          order_by: [asc: slot.start_time],
          preload: [service: service, resource: resource]
        )
      )

    existing_by_window =
      Map.new(existing_slots, fn slot ->
        {generated_occurrence_key(slot.start_time, slot.end_time), slot}
      end)

    post
    |> build_auto_virtual_windows(from_dt, to_dt)
    |> Enum.map(fn %{start_time: start_time, end_time: end_time} = window ->
      case Map.get(existing_by_window, generated_occurrence_key(start_time, end_time)) do
        %UserSlot{} = slot ->
          slot_to_view(post, slot, slot_booking_count(slot.id))

        nil ->
          window
          |> Map.put(:id, generated_virtual_slot_id(post.id, start_time, end_time))
          |> Map.put(:status, :available)
          |> Map.put(:service_id, post.service_id)
          |> Map.put(:resource_id, post.resource_id)
          |> Map.put(:source_type, :generated)
          |> Map.put(:max_bookings, post.default_max_bookings)
          |> Map.put(:booking_count, 0)
          |> Map.put(:remaining_capacity, remaining_capacity(post.default_max_bookings, 0))
          |> Map.put(:service_name, post.service && post.service.name)
          |> Map.put(:resource_name, post.resource && post.resource.name)
          |> Map.put(:service_price, post.service && post.service.price)
          |> Map.put(:resource_price, post.resource && post.resource.price)
          |> Map.put(:currency, resolve_slot_currency(post.service && post.service.currency, post.resource && post.resource.currency))
      end
    end)
    |> Enum.filter(&slot_open_for_booking?/1)
  end

  defp manual_slot_scope(%Post{} = post) do
    global_scope =
      cond do
        is_binary(post.service_id) and is_binary(post.resource_id) ->
          dynamic([slot], is_nil(slot.post_id) and slot.service_id == ^post.service_id and slot.resource_id == ^post.resource_id)

        is_binary(post.service_id) ->
          dynamic([slot], is_nil(slot.post_id) and slot.service_id == ^post.service_id)

        is_binary(post.resource_id) ->
          dynamic([slot], is_nil(slot.post_id) and slot.resource_id == ^post.resource_id)

        true ->
          dynamic([slot], false)
      end

    dynamic([slot], slot.post_id == ^post.id or ^global_scope)
  end

  defp build_auto_virtual_windows(%Post{} = post, from_dt, to_dt) do
    with true <- post.auto_slots_enabled,
         %Date{} = schedule_start <- post.schedule_start_date,
         %Date{} = schedule_end <- post.schedule_end_date,
         %Time{} = work_start <- post.work_start_time,
         %Time{} = work_end <- post.work_end_time do
      timezone = post_timezone(post)
      range_start = max_date(schedule_start, DateTime.to_date(shift_datetime_to_timezone(from_dt, timezone)))
      range_end = min_date(schedule_end, DateTime.to_date(shift_datetime_to_timezone(to_dt, timezone)))

      if Date.before?(range_end, range_start) do
        []
      else
        weekdays = parse_available_weekdays(post.available_weekdays)
        excluded_dates = parse_excluded_dates(post.excluded_dates)

        range_start
        |> Date.range(range_end)
        |> Enum.flat_map(fn date ->
          if date_allowed_for_post?(date, weekdays, excluded_dates) do
            build_auto_windows_for_day(post, date, timezone, work_start, work_end, from_dt, to_dt)
          else
            []
          end
        end)
      end
    else
      _ -> []
    end
  end

  defp build_auto_windows_for_day(%Post{} = post, date, timezone, work_start, work_end, from_dt, to_dt) do
    with {:ok, work_start_dt} <- build_local_datetime(date, work_start, timezone),
         {:ok, work_end_dt} <- build_local_datetime(date, work_end, timezone) do
      lunch_range = lunch_range_for_post(post, date, timezone)
      slot_minutes = post.slot_minutes || 60
      break_minutes = post.break_minutes || 0

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

  defp slot_to_view(post, %UserSlot{} = slot, booking_count) do
    service = if Ecto.assoc_loaded?(slot.service), do: slot.service
    resource = if Ecto.assoc_loaded?(slot.resource), do: slot.resource

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
      service_name: service && service.name,
      resource_name: resource && resource.name,
      service_price: service && service.price,
      resource_price: resource && resource.price,
      currency: resolve_slot_currency(service && service.currency, resource && resource.currency),
      timezone: post_timezone(post)
    }
  end

  defp resolve_booking_slot(_post, nil), do: {:error, :unavailable}

  defp resolve_booking_slot(%Post{} = post, slot_id) do
    case Ecto.UUID.cast(slot_id) do
      {:ok, persisted_id} ->
        slot =
          UserSlot
          |> where([slot], slot.id == ^persisted_id)
          |> maybe_lock_for_update()
          |> Repo.one()

        with {:ok, slot} <- ensure_slot_available(slot),
             booking_count = slot_booking_count(slot.id),
             :ok <- ensure_slot_has_capacity(slot, booking_count) do
          {:ok, Repo.preload(slot, [:service, :resource]), booking_count}
        end

      :error ->
        with {:ok, start_time, end_time} <- parse_generated_virtual_slot_id(post.id, slot_id),
             :ok <- ensure_virtual_slot_matches_post_schedule(post, start_time, end_time),
             {:ok, slot} <- get_or_create_generated_slot(post, start_time, end_time),
             {:ok, slot} <- ensure_slot_available(slot),
             booking_count = slot_booking_count(slot.id),
             :ok <- ensure_slot_has_capacity(slot, booking_count) do
          {:ok, Repo.preload(slot, [:service, :resource]), booking_count}
        end
    end
  end

  defp ensure_slot_available(nil), do: {:error, :unavailable}
  defp ensure_slot_available(%UserSlot{status: :available} = slot), do: {:ok, slot}
  defp ensure_slot_available(_slot), do: {:error, :unavailable}

  defp ensure_slot_has_capacity(%UserSlot{max_bookings: nil}, _booking_count), do: :ok

  defp ensure_slot_has_capacity(%UserSlot{max_bookings: max_bookings}, booking_count) when is_integer(max_bookings) and booking_count < max_bookings, do: :ok

  defp ensure_slot_has_capacity(%UserSlot{}, _booking_count), do: {:error, :slot_full}

  defp get_booking_service(%UserSlot{service_id: nil}), do: {:ok, nil}

  defp get_booking_service(%UserSlot{service_id: service_id}) do
    case Repo.get(UserService, service_id) do
      nil -> {:error, :slot_not_shareable}
      service -> {:ok, service}
    end
  end

  defp get_booking_resource(%UserSlot{resource_id: nil}), do: {:ok, nil}

  defp get_booking_resource(%UserSlot{resource_id: resource_id}) do
    case Repo.get(UserResource, resource_id) do
      nil -> {:error, :slot_not_shareable}
      resource -> {:ok, resource}
    end
  end

  defp ensure_slot_owned_by_post_owner(post, service, resource) do
    with :ok <- ensure_service_owner(service, post.user_id) do
      ensure_resource_owner(resource, post.user_id)
    end
  end

  defp ensure_service_owner(nil, _owner_id), do: :ok

  defp ensure_service_owner(%{user_id: owner_id}, owner_id), do: :ok
  defp ensure_service_owner(_service, _owner_id), do: {:error, :slot_not_shareable}

  defp ensure_resource_owner(nil, _owner_id), do: :ok
  defp ensure_resource_owner(%{user_id: owner_id}, owner_id), do: :ok
  defp ensure_resource_owner(_resource, _owner_id), do: {:error, :slot_not_shareable}

  defp ensure_slot_matches_post(post, slot) do
    with :ok <- ensure_target_match(post.service_id, slot.service_id),
         :ok <- ensure_target_match(post.resource_id, slot.resource_id) do
      ensure_post_target_match(post.id, slot.post_id)
    end
  end

  defp ensure_target_match(nil, _slot_target_id), do: :ok
  defp ensure_target_match(post_target_id, post_target_id), do: :ok
  defp ensure_target_match(_post_target_id, _slot_target_id), do: {:error, :slot_not_shareable}

  defp ensure_post_target_match(_post_id, nil), do: :ok
  defp ensure_post_target_match(post_id, post_id), do: :ok
  defp ensure_post_target_match(_post_id, _slot_post_id), do: {:error, :slot_not_shareable}

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
    Repo.aggregate(from(booking in UserBooking, where: booking.slot_id == ^slot_id), :count, :id)
  end

  defp slot_open_for_booking?(%{status: status}) when status != :available, do: false
  defp slot_open_for_booking?(%{remaining_capacity: remaining_capacity}) when is_integer(remaining_capacity), do: remaining_capacity > 0
  defp slot_open_for_booking?(_slot), do: true

  defp remaining_capacity(nil, _booking_count), do: nil
  defp remaining_capacity(max_bookings, booking_count), do: max(max_bookings - booking_count, 0)

  defp generated_virtual_slot_id(post_id, start_time, end_time) do
    "virtual:#{post_id}:#{DateTime.to_unix(start_time)}:#{DateTime.to_unix(end_time)}"
  end

  defp parse_generated_virtual_slot_id(post_id, "virtual:" <> payload) do
    case String.split(payload, ":") do
      [^post_id, start_unix, end_unix] ->
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

  defp parse_generated_virtual_slot_id(_post_id, _slot_id), do: {:error, :unavailable}

  defp generated_occurrence_key(%DateTime{} = start_time, %DateTime{} = end_time) do
    "#{DateTime.to_unix(start_time)}:#{DateTime.to_unix(end_time)}"
  end

  defp ensure_virtual_slot_matches_post_schedule(%Post{} = post, start_time, end_time) do
    post
    |> build_auto_virtual_windows(start_time, end_time)
    |> Enum.find(fn slot ->
      DateTime.compare(slot.start_time, start_time) == :eq and DateTime.compare(slot.end_time, end_time) == :eq
    end)
    |> case do
      nil -> {:error, :unavailable}
      _slot -> :ok
    end
  end

  defp get_or_create_generated_slot(%Post{} = post, start_time, end_time) do
    case Repo.one(
           from(slot in UserSlot,
             where:
               slot.post_id == ^post.id and slot.source_type == :generated and
                 slot.start_time == ^start_time and slot.end_time == ^end_time
           )
         ) do
      %UserSlot{} = slot ->
        {:ok, slot}

      nil ->
        %UserSlot{}
        |> UserSlot.changeset(%{
          "post_id" => post.id,
          "source_type" => "generated",
          "max_bookings" => post.default_max_bookings,
          "start_time" => start_time,
          "end_time" => end_time,
          "status" => "available",
          "service_id" => post.service_id,
          "resource_id" => post.resource_id
        })
        |> Repo.insert()
        |> case do
          {:ok, slot} -> {:ok, slot}
          {:error, changeset} -> {:error, changeset}
        end
    end
  end

  defp maybe_close_full_slot(%UserSlot{max_bookings: nil}, _booking_count_after), do: :ok

  defp maybe_close_full_slot(%UserSlot{} = slot, booking_count_after) do
    if is_integer(slot.max_bookings) and booking_count_after >= slot.max_bookings and slot.status == :available do
      Repo.update!(Ecto.Changeset.change(slot, status: :booked))
    end

    :ok
  end

  defp insert_booking(slot, pricing, attrs) do
    %UserBooking{}
    |> UserBooking.changeset(%{
      slot_id: slot.id,
      user_id: map_get(attrs, "user_id"),
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

  defp first_present(nil, fallback), do: fallback
  defp first_present("", fallback), do: fallback
  defp first_present(value, _fallback), do: value

  defp money(nil), do: D.new(0)
  defp money(value), do: value

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

  defp date_allowed_for_post?(date, weekdays, excluded_dates) do
    weekday_key = weekday_name(date)
    MapSet.member?(weekdays, weekday_key) and not MapSet.member?(excluded_dates, date)
  end

  defp lunch_range_for_post(%Post{lunch_start_time: nil, lunch_end_time: nil}, _date, _timezone), do: nil

  defp lunch_range_for_post(%Post{lunch_start_time: lunch_start, lunch_end_time: lunch_end}, date, timezone) when not is_nil(lunch_start) and not is_nil(lunch_end) do
    with {:ok, lunch_start_dt} <- build_local_datetime(date, lunch_start, timezone),
         {:ok, lunch_end_dt} <- build_local_datetime(date, lunch_end, timezone) do
      {lunch_start_dt, lunch_end_dt}
    else
      _ -> nil
    end
  end

  defp lunch_overlap?(nil, _start_time, _end_time), do: false

  defp lunch_overlap?({lunch_start, lunch_end}, start_time, end_time) do
    DateTime.before?(start_time, lunch_end) and DateTime.after?(end_time, lunch_start)
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

  defp map_get(map, key) do
    Map.get(map, key) || Map.get(map, String.to_existing_atom(key))
  rescue
    ArgumentError -> Map.get(map, key)
  end

  defp stringify_keys(attrs) do
    Map.new(attrs, fn
      {key, value} when is_atom(key) -> {Atom.to_string(key), value}
      {key, value} -> {key, value}
    end)
  end

  defp maybe_lock_for_update(query) do
    if Repo.__adapter__() == Ecto.Adapters.SQLite3 do
      query
    else
      lock(query, "FOR UPDATE")
    end
  end
end
