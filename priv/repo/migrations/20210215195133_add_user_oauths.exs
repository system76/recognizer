defmodule Recognizer.Repo.Migrations.AddUserOauths do
  use Ecto.Migration

  def change do
    create table(:user_oauths) do
      add :service, :"enum('facebook','github','google')"
      add :service_guid, :string

      add :user_id, references(:users, type: :"int(11) unsigned", on_delete: :nothing)
    end
  end
end
