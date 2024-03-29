defmodule Recognizer.Repo.Migrations.CreateUsersAuthTables do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :"int(11) unsigned not null auto_increment", primary_key: true
      add :first_name, :string, null: false
      add :last_name, :string, null: false
      add :username, :string, null: false
      add :email, :string, null: false, size: 160
      add :password, :string

      timestamps()
    end

    create unique_index(:users, [:email])

    create table(:users_tokens) do
      add :user_id, references(:users, type: :"int(11) unsigned", on_delete: :delete_all),
        null: false

      add :token, :binary, null: false, size: 32
      add :context, :string, null: false
      add :sent_to, :string

      timestamps(updated_at: false)
    end

    create index(:users_tokens, [:user_id])
    create unique_index(:users_tokens, [:context, :token])

    # This table was created by a migration in a different application.
    create table(:bigcommerce_customer_users, primary_key: false) do
      add :bc_id, :integer, null: false
      add :user_id, references(:users, type: :"int(11) unsigned"), null: false, primary_key: true

      timestamps()
    end
  end
end
