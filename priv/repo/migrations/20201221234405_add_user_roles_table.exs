defmodule Recognizer.Repo.Migrations.AddUserRolesTable do
  use Ecto.Migration

  def change do
    create table(:roles_users, primary_key: false) do
      add :user_id, references(:users, type: :"int(10) unsigned"), null: false, primary_key: true
      add :role_id, :"int(10) unsigned", null: false, primary_key: true
    end
  end
end
