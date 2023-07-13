defmodule Hal.Repo.Migrations.AddVerifiedAtToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :verified_at, :utc_datetime, null: true
    end
  end
end
