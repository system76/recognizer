defmodule Recognizer.Repo.Migrations.AddOrgAuthPolicy do
  use Ecto.Migration

    def change do
      alter table(:organizations) do
        add :password_reuse, :integer, default: 6
        add :password_expiration, :integer, default: 90
        add :two_factor_app_required, :boolean, default: false
      end

      alter table(:users) do
        add :password_changed_at, :naive_datetime
      end
    end

end
