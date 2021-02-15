defmodule Recognizer.Repo.Migrations.AddUserOauths do
  use Ecto.Migration

  #  This migration is used for our existing database. It's commented out because
  #  we will eventually move authentication to it's own database and this code
  #  can be deleted.
  #
  #  def change do
  #    #
  #  end

  def change do
    create table(:user_oauths) do
      add :service, :"enum('facebook','github','google')"
      add :service_guid, :string

      add :user_id, references(:users, type: "int(11) unsigned", on_delete: :nothing)
    end
  end
end
