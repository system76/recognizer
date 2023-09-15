defmodule Hal.Repo.Migrations.AddVerificationCodesTable do
  use Ecto.Migration

  def change do
    create table(:verification_codes) do
      add :user_id, :bigint, null: false
      add :code, :text, null: false

      timestamps()
    end
  end
end
