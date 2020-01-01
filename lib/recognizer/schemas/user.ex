defmodule Recognizer.Schemas.User do
  @moduledoc """
  The representation of our user
  """
  use Ecto.Schema

  import Ecto.Changeset

  alias Recognizer.Schemas.Role

  schema "users" do
    field :avatar_filename, :string
    field :company_name, :string
    field :email, :string
    field :first_name, :string
    field :last_name, :string
    field :newsletter, :boolean
    field :password_hash, :string
    field :phone_number, :string
    field :type, :string
    field :username, :string

    field :password, :string, virtual: true
    field :password_confirmation, :string, virtual: true

    many_to_many :roles, Role, join_through: "roles_users"

    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [
      :avatar_filename,
      :email,
      :first_name,
      :last_name,
      :newsletter,
      :password,
      :password_confirmation,
      :phone_number
    ])
    |> validate_required([:email, :first_name, :last_name, :phone_number])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password()
    |> hash_password_changes()
    |> unique_constraint(:email)
  end

  defp hash_password_changes(%{valid?: true, changes: %{password: password}} = changeset),
    do: change(changeset, Argon2.add_hash(password))

  defp hash_password_changes(changeset),
    do: changeset

  defp validate_password(%{valid?: true, changes: %{password: _password}} = changeset) do
    changeset
    |> validate_length(:password, min: 8)
    |> validate_format(:password, ~r/[0-9]/, message: "must contain a number")
    |> validate_format(:password, ~r/[A-Z]/, message: "must contain an UPPERCASE letter")
    |> validate_format(:password, ~r/[a-z]/, message: "must contain a lowercase letter")
    |> validate_format(:password, ~r/[ \!\$\*\+\[\{\]\}\\\|\.\/\?,!@#%^&-=,.<>'";:]/,
      message: "must contain a symbol or space"
    )
  end

  defp validate_password(%{data: %{password_hash: hash}} = changeset) when not is_nil(hash) do
    changeset
  end

  defp validate_password(%{valid?: true} = changeset) do
    add_error(changeset, :password, "can't be blank")
  end

  defp validate_password(changeset) do
    changeset
  end
end
