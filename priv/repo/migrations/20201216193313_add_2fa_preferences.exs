defmodule Recognizer.Repo.Migrations.Add2faPreferences do
  use Ecto.Migration

  def change do
    modify table(:users) do
      add(:two_factor_enabled, :boolean, default: false)
      add(:two_factor_recovery_codes, :string)
    end

    create table(:notification_preferences) do
      add(:user_id, references(:users), null: false)
      add(:two_factor, Recognizer.TwoFactorPreference, default: "text")

      timestamps()
    end
  end
end
