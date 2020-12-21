defmodule Recognizer.Repo.Migrations.UpdateUserFields do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :phone_number, :string

      add :type, :string, default: "individual"
      add :company_name, :string

      add :newsletter, :boolean
    end
  end
end
