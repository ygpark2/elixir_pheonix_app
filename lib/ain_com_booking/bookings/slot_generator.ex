defmodule AinComBooking.Bookings.SlotGenerator do
  @moduledoc false
  alias AinComBooking.Bookings.CompanySlot
  alias AinComBooking.Bookings.UserSlot
  alias AinComBooking.Repo

  # minutes
  @slot_duration 30
  # minutes
  @slot_gap 10
  @tz "Asia/Seoul"

  def generate_slots(%{
        from: from_date,
        to: to_date,
        work_days: work_days,
        work_hours: %{start: start_time, end: end_time},
        holidays: holidays,
        slot_type: slot_type,
        extra_fields: extra_fields
      }) do
    module = slot_module(slot_type)

    from_date
    |> Date.range(to_date)
    |> Enum.flat_map(fn date ->
      if Date.day_of_week(date) in work_days and date not in holidays do
        build_day_slots(date, start_time, end_time, module, extra_fields)
      else
        []
      end
    end)
    |> Enum.each(&Repo.insert!/1)
  end

  defp build_day_slots(date, start_t, end_t, module, extra_fields) do
    start_dt = DateTime.new!(date, start_t, @tz)
    end_dt = DateTime.new!(date, end_t, @tz)

    start_dt
    |> Stream.unfold(fn dt ->
      next_start = DateTime.add(dt, (@slot_duration + @slot_gap) * 60, :second)
      next_end = DateTime.add(dt, @slot_duration * 60, :second)

      if DateTime.before?(next_end, end_dt) do
        slot =
          struct(
            module,
            Map.merge(extra_fields, %{
              start_time: DateTime.to_time(dt),
              end_time: DateTime.to_time(next_end),
              date: DateTime.to_date(dt),
              status: :available
            })
          )

        {slot, next_start}
      end
    end)
    |> Enum.to_list()
  end

  defp slot_module(:company), do: CompanySlot
  defp slot_module(:user), do: UserSlot
end
