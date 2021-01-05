defmodule Recognizer.Repo.Migrations.AddPreviouslyUsedPasswordTable do
  use Ecto.Migration

  def change do
    create table(:previous_passwords) do
      add :user_id, references(:users, type: "int(11) unsigned", on_delete: :delete_all),
        null: false

      add :hashed_password, :string, null: false

      timestamps()
    end

    create unique_index(:previous_passwords, [:user_id, :hashed_password])
  end
end
