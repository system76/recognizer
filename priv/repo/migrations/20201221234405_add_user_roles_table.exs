defmodule Recognizer.Repo.Migrations.AddUserRolesTable do
  use Ecto.Migration

  #  This migration is used for our existing database. It's commented out because
  #  we will eventually move authentication to it's own database and this code
  #  can be deleted. As you can see, it's empty, because our production database
  #  already has this table.
  #
  #  def change do
  #    #
  #  end

  def change do
    create table(:roles_users, primary_key: false) do
      add :user_id, references(:users, type: :"int(10) unsigned"), null: false, primary_key: true
      add :role_id, :"int(10) unsigned", null: false, primary_key: true
    end
  end
end
