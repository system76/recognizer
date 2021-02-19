defmodule Recognizer.Repo.Migrations.AddUserStripeId do
  use Ecto.Migration

  #  This migration is used for our existing database. It's commented out because
  #  we will eventually move authentication to it's own database and this code
  #  can be deleted.
  #
  #  def change do
  #    #
  #  end

  def change do
    alter table(:users) do
      add :stripe_id, :string
    end
  end
end
