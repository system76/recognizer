defmodule Recognizer.Repo.Migrations.CreateUsersTokensTable do
  use Ecto.Migration

  def change do
    create table(:users_tokens, primary_key: false) do
      add(:jti, :string, primary_key: true)
      add(:aud, :string, primary_key: true)
      add(:typ, :string)
      add(:iss, :string)
      add(:sub, :string)
      add(:exp, :bigint)
      add(:jwt, :text)
      add(:claims, :map)
      timestamps()
    end
  end
end
