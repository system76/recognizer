defmodule Recognizer.Repo.Migrations.AddRecoveryCodes do
  use Ecto.Migration

  def change do
    create table(:recovery_codes) do
      add :code, :string, null: false

      add :user_id, references(:users, type: :"int(10) unsigned", on_delete: :delete_all),
        null: false

      timestamps()
    end
  end
end
