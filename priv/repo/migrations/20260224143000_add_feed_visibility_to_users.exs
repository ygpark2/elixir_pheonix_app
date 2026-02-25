defmodule AinComBooking.Repo.Migrations.AddFeedVisibilityToUsers do
  @moduledoc false
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:feed_visibility, :string, null: false, default: "public")
    end
  end
end
