defmodule Recognizer.Repo.Migrations.CreateUsersAuthTables do
  use Ecto.Migration

  def change do
    create_if_not_exists table(:users) do
      add :first_name, :string, null: false
      add :last_name, :string, null: false
      add :username, :string, null: false
      add :email, :string, null: false, size: 160
      add :password, :string

      timestamps()
    end

    create unique_index(:users, [:email])

    create_if_not_exists table(:users_tokens) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :token, :binary, null: false, size: 32
      add :context, :string, null: false
      add :sent_to, :string

      timestamps(updated_at: false)
    end

    create index(:users_tokens, [:user_id])
    create unique_index(:users_tokens, [:context, :token])
  end
end
