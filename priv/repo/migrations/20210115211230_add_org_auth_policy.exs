defmodule Recognizer.Repo.Migrations.AddOrgAuthPolicy do
  use Ecto.Migration

  def change do
    create table(:organizations) do
      add :name, :string, null: false
      add :password_reuse, :integer, default: nil
      add :password_expiration, :integer, default: nil
      add :two_factor_required, :boolean, default: false
      timestamps()
    end

    # alter table(:organizations) do
    #   add :password_reuse, :integer, default: 6
    #   add :password_expiration, :integer, default: 90
    #   add :two_factor_required, :boolean, default: false
    #   timestamps()
    # end

    alter table(:users) do
      add :password_changed_at, :naive_datetime
      add :organization_id, references(:organizations)
    end
  end
end
