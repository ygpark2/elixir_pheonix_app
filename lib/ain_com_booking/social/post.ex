defmodule AinComBooking.Social.Post do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "social_posts" do
    field(:body, :string)
    field(:booking_note, :string)
    field(:visibility, Ecto.Enum, values: [:public, :followers, :private], default: :public)
    field(:auto_slots_enabled, :boolean, default: false)
    field(:schedule_start_date, :date)
    field(:schedule_end_date, :date)
    field(:work_start_time, :time)
    field(:work_end_time, :time)
    field(:slot_minutes, :integer, default: 60)
    field(:break_minutes, :integer, default: 10)
    field(:lunch_start_time, :time)
    field(:lunch_end_time, :time)
    field(:available_weekdays, :string, default: "mon,tue,wed,thu,fri")
    field(:excluded_dates, :string, default: "")
    field(:default_max_bookings, :integer)
    field(:timezone, :string, default: "Asia/Seoul")

    belongs_to(:user, AinComBooking.Accounts.User, type: :binary_id)
    belongs_to(:service, AinComBooking.Catalog.UserService, type: :binary_id)
    belongs_to(:resource, AinComBooking.Catalog.UserResource, type: :binary_id)
    has_many(:slots, AinComBooking.Bookings.UserSlot, foreign_key: :post_id)

    timestamps()
  end

  def changeset(post, attrs) do
    post
    |> cast(attrs, [
      :body,
      :booking_note,
      :visibility,
      :auto_slots_enabled,
      :schedule_start_date,
      :schedule_end_date,
      :work_start_time,
      :work_end_time,
      :slot_minutes,
      :break_minutes,
      :lunch_start_time,
      :lunch_end_time,
      :available_weekdays,
      :excluded_dates,
      :default_max_bookings,
      :timezone,
      :user_id,
      :service_id,
      :resource_id
    ])
    |> validate_required([:body, :booking_note, :visibility, :user_id])
    |> validate_length(:body, min: 4, max: 280)
    |> validate_length(:booking_note, min: 4, max: 500)
    |> validate_length(:available_weekdays, max: 64)
    |> validate_length(:excluded_dates, max: 1000)
    |> validate_length(:timezone, min: 1, max: 50)
    |> validate_number(:slot_minutes, greater_than: 0)
    |> validate_number(:break_minutes, greater_than_or_equal_to: 0)
    |> validate_number(:default_max_bookings, greater_than: 0)
    |> validate_share_target_present()
    |> validate_auto_schedule()
    |> assoc_constraint(:user)
    |> assoc_constraint(:service)
    |> assoc_constraint(:resource)
  end

  defp validate_share_target_present(changeset) do
    service_id = get_field(changeset, :service_id)
    resource_id = get_field(changeset, :resource_id)

    if is_nil(service_id) and is_nil(resource_id) do
      changeset
      |> add_error(:service_id, "choose a service or resource to share")
      |> add_error(:resource_id, "choose a service or resource to share")
    else
      changeset
    end
  end

  defp validate_auto_schedule(changeset) do
    if get_field(changeset, :auto_slots_enabled) do
      changeset
      |> validate_required([:schedule_start_date, :schedule_end_date, :work_start_time, :work_end_time, :available_weekdays, :timezone])
      |> validate_schedule_date_range()
      |> validate_work_time_range()
      |> validate_lunch_range()
    else
      changeset
    end
  end

  defp validate_schedule_date_range(changeset) do
    start_date = get_field(changeset, :schedule_start_date)
    end_date = get_field(changeset, :schedule_end_date)

    if is_nil(start_date) or is_nil(end_date) or Date.compare(end_date, start_date) in [:gt, :eq] do
      changeset
    else
      add_error(changeset, :schedule_end_date, "must be on or after the start date")
    end
  end

  defp validate_work_time_range(changeset) do
    start_time = get_field(changeset, :work_start_time)
    end_time = get_field(changeset, :work_end_time)

    if is_nil(start_time) or is_nil(end_time) or Time.after?(end_time, start_time) do
      changeset
    else
      add_error(changeset, :work_end_time, "must be after the work start time")
    end
  end

  defp validate_lunch_range(changeset) do
    lunch_start = get_field(changeset, :lunch_start_time)
    lunch_end = get_field(changeset, :lunch_end_time)

    cond do
      is_nil(lunch_start) and is_nil(lunch_end) ->
        changeset

      is_nil(lunch_start) or is_nil(lunch_end) ->
        changeset
        |> add_error(:lunch_start_time, "set both lunch times or leave both blank")
        |> add_error(:lunch_end_time, "set both lunch times or leave both blank")

      Time.after?(lunch_end, lunch_start) ->
        changeset

      true ->
        add_error(changeset, :lunch_end_time, "must be after lunch start time")
    end
  end
end
