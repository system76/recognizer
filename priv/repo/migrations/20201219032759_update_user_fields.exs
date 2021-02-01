defmodule Recognizer.Repo.Migrations.UpdateUserFields do
  use Ecto.Migration

  #  This migration is used for our existing database. It's commented out because
  #  we will eventually move authentication to it's own database and this code
  #  can be deleted. As you can see, it's empty, because our production database
  #  already has these fields.
  #
  #  def change do
  #    #
  #  end

  def change do
    alter table(:users) do
      add :phone_number, :string

      add :type, :string, default: "individual"
      add :company_name, :string

      add :newsletter, :boolean
    end
  end
end
