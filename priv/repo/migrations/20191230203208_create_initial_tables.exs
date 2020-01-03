defmodule Recognizer.Repo.Migrations.CreateInitialTables do
  use Ecto.Migration

  def change do
    create table(:audiences) do
      add :name, :string, null: false
      add :token, :string, null: false

      timestamps()
    end

    create unique_index(:audiences, :token)

    create_if_not_exists table(:users) do
      add :avatar_filename, :string
      add :company_name, :string
      add :email, :string, null: false
      add :first_name, :string
      add :last_name, :string
      add :newsletter, :boolean, default: true
      add :password_hash, :string, null: false
      add :phone_number, :string
      add :type, :string
      add :username, :string

      timestamps()
    end

    create_if_not_exists table(:roles) do
      add :name, :string
      add :description, :string

      timestamps()
    end

    create_if_not_exists table(:roles_users, primary_key: false) do
      add :role_id, references(:roles, on_delete: :nothing), primary_key: true
      add :user_id, references(:users, on_delete: :nothing), primary_key: true

      timestamps()
    end
  end
end
