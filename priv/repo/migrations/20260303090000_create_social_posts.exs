defmodule AinComBooking.Repo.Migrations.CreateSocialPosts do
  @moduledoc false
  use Ecto.Migration

  def change do
    create table(:social_posts, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:body, :text, null: false)
      add(:booking_note, :text, null: false)
      add(:visibility, :string, null: false, default: "public")
      add(:auto_slots_enabled, :boolean, null: false, default: false)
      add(:schedule_start_date, :date)
      add(:schedule_end_date, :date)
      add(:work_start_time, :time)
      add(:work_end_time, :time)
      add(:slot_minutes, :integer, null: false, default: 60)
      add(:break_minutes, :integer, null: false, default: 10)
      add(:lunch_start_time, :time)
      add(:lunch_end_time, :time)
      add(:available_weekdays, :string, null: false, default: "mon,tue,wed,thu,fri")
      add(:excluded_dates, :text, null: false, default: "")
      add(:default_max_bookings, :integer)
      add(:timezone, :string, null: false, default: "Asia/Seoul")

      add(:user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false)
      add(:service_id, references(:user_services, type: :binary_id, on_delete: :nilify_all))
      add(:resource_id, references(:user_resources, type: :binary_id, on_delete: :nilify_all))

      timestamps()
    end

    create(index(:social_posts, [:user_id, :inserted_at]))
    create(index(:social_posts, [:visibility, :inserted_at]))
    create(index(:social_posts, [:service_id]))
    create(index(:social_posts, [:resource_id]))
  end
end
