defmodule Recognizer.Repo.Migrations.UniqueUserIdNotificationPreferences do
  use Ecto.Migration

  def change do
    create unique_index(:notification_preferences, [:user_id])
  end
end
