defmodule AinComBookingApi.Bookings.SlotGenerator do
  @moduledoc false
  alias AinComBookingApi.Bookings.Slot
  alias AinComBookingApi.Repo

  # minutes
  @slot_duration 30
  # minutes
  @slot_gap 10
  @tz "Asia/Seoul"

  def generate_slots(%{from: from_date, to: to_date, work_days: work_days, work_hours: %{start: start_time, end: end_time}, holidays: holidays}) do
    from_date
    |> Date.range(to_date)
    |> Enum.flat_map(fn date ->
      if Date.day_of_week(date) in work_days and date not in holidays do
        build_day_slots(date, start_time, end_time)
      else
        []
      end
    end)
    |> Enum.each(&Repo.insert!/1)
  end

  defp build_day_slots(date, start_t, end_t) do
    start_dt = DateTime.new!(date, start_t, @tz)
    end_dt = DateTime.new!(date, end_t, @tz)

    start_dt
    |> Stream.unfold(fn dt ->
      next_start = DateTime.add(dt, (@slot_duration + @slot_gap) * 60, :second)
      next_end = DateTime.add(dt, @slot_duration * 60, :second)

      if DateTime.before?(next_end, end_dt) do
        slot = %Slot{
          start_time: dt,
          end_time: next_end,
          status: "available"
        }

        {slot, next_start}
      end
    end)
    |> Enum.to_list()
  end
end
