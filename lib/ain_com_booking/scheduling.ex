defmodule AinComBooking.Scheduling do
  @moduledoc false
  import Ecto.Query, warn: false

  alias AinComBooking.Accounts.User
  alias AinComBooking.Repo
  alias AinComBooking.Scheduling.BreakTime
  alias AinComBooking.Scheduling.DayOff
  alias AinComBooking.Scheduling.WorkingHour

  @weekday_order %{mon: 1, tue: 2, wed: 3, thu: 4, fri: 5, sat: 6, sun: 7}

  @doc """
  Builds a weekly schedule summary used by the social feed.
  """
  def weekly_summary_for_feed(%User{feed_visibility: visibility}) when visibility in [:link, :private] do
    hidden_summary()
  end

  def weekly_summary_for_feed(%User{id: user_id}) when is_binary(user_id) do
    %{
      visible?: true,
      working_hours: list_working_hours(user_id),
      break_times: list_break_times(user_id),
      day_offs: list_day_offs(user_id)
    }
  end

  defp list_working_hours(user_id) do
    from(wh in WorkingHour,
      where: wh.user_id == ^user_id and wh.owner_type == :user,
      select: %{
        weekday: wh.weekday,
        start_time: wh.start_time,
        end_time: wh.end_time,
        is_day_off: wh.is_day_off
      }
    )
    |> Repo.all()
    |> Enum.sort_by(fn row -> {Map.fetch!(@weekday_order, row.weekday), row.start_time || ~T[00:00:00]} end)
  end

  defp list_break_times(user_id) do
    from(bt in BreakTime,
      where: bt.user_id == ^user_id and bt.owner_type == :user,
      select: %{
        weekday: bt.weekday,
        start_time: bt.start_time,
        end_time: bt.end_time
      }
    )
    |> Repo.all()
    |> Enum.sort_by(fn row -> {Map.fetch!(@weekday_order, row.weekday), row.start_time || ~T[00:00:00]} end)
  end

  defp list_day_offs(user_id) do
    today = Date.utc_today()
    week_end = Date.add(today, 6)

    Repo.all(
      from(doff in DayOff,
        where: doff.user_id == ^user_id and doff.owner_type == :user and doff.date >= ^today and doff.date <= ^week_end,
        order_by: [asc: doff.date],
        select: %{date: doff.date, reason: doff.reason}
      )
    )
  end

  defp hidden_summary do
    %{
      visible?: false,
      working_hours: [],
      break_times: [],
      day_offs: []
    }
  end
end
