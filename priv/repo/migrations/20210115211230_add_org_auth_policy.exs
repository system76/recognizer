defmodule Recognizer.Repo.Migrations.AddOrgAuthPolicy do
  use Ecto.Migration

  #  This migration is used for our existing database. It's commented out because
  #  we will eventually move authentication to it's own database and this code
  #  can be deleted.
  #
  #  def change do
  #    alter table(:organizations) do
  #      add :password_reuse, :integer, default: 6
  #      add :password_expiration, :integer, default: 90
  #      add :two_factor_app_required, :boolean, default: false
  #    end
  #
  #    alter table(:users) do
  #      add :password_changed_at, :naive_datetime
  #    end
  #  end

  def change do
    create table(:organizations) do
      add :name, :string, null: false

      add :password_reuse, :integer, default: nil
      add :password_expiration, :integer, default: nil
      add :two_factor_app_required, :boolean, default: false

      timestamps()
    end

    alter table(:users) do
      add :password_changed_at, :naive_datetime
      add :organization_id, references(:organizations)
    end
  end
end
