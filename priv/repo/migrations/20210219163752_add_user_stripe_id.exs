defmodule Recognizer.Repo.Migrations.AddUserStripeId do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :stripe_id, :string
    end
  end
end
