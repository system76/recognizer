defmodule Recognizer.Schemas.User do
  @moduledoc """
  The a simple representation of our user with only the auth fields
  """
  use Ecto.Schema

  alias Recognizer.Schemas.Role

  schema "users" do
    field :avatar_filename, :string
    field :company_name, :string
    field :email, :string
    field :first_name, :string
    field :last_name, :string
    field :password_hash, :string
    field :type, :string
    field :username, :string

    many_to_many :roles, Role, join_through: "roles_users"

    timestamps()
  end
end
