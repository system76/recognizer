defmodule Recognizer.Repo.Migrations.CreateUsersAuthTables do
  use Ecto.Migration

  #  These migrations are adjusted to work with an internal service, not necessary for a standalone database.

    def change do
      alter table(:users) do
        modify :first_name, :string, null: false
        modify :last_name, :string, null: false
        modify :username, :string, null: false
        modify :email, :string, null: false, size: 160
        modify :password, :string

      end


      alter table(:users_tokens) do
        add :user_id, references(:users, type: :"int(11) unsigned", on_delete: :delete_all), null: false
        add :token, :binary, null: false, size: 32
        add :context, :string, null: false
        add :sent_to, :string

      end

      execute "UPDATE users SET inserted_at = NOW(), updated_at = NOW();";

      create index(:users_tokens, [:user_id])
    end

end
