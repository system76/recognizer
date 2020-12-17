defmodule Recognizer.Repo.Migrations.Add2faPreferences do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :two_factor_enabled, :boolean, default: false
      add :two_factor_seed, :string
    end

    create table(:notification_preferences) do
      add :user_id, references(:users, type: :"int(11) unsigned"), null: true
      add :two_factor, :string, default: "text"

      timestamps()
    end
  end
end
