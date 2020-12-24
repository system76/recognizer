defmodule Recognizer.Accounts.Role do
  @moduledoc """
  `Ecto.Schema` for user roles. This is an old schema based on our database as
  it currently is. There are plenty of optimizations and better layouts we could
  do, but we are stuck til we can break support for old applications.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Recognizer.Accounts.User

  @admin_role_id 2
  @login_role_id 1

  @primary_key false

  schema "roles_users" do
    field :role_id, :integer

    belongs_to :user, User
  end

  def changeset(role, attrs \\ %{}) do
    role
    |> cast(attrs, [:user_id, :role_id])
    |> validate_required([:user_id, :role_id])
  end

  def default_role_changeset() do
    [
      %{role_id: @login_role_id}
    ]
  end

  def admin?(%{roles: roles}), do: admin?(roles)

  def admin?(roles) when is_list(roles) do
    Enum.any?(roles, fn r ->
      r.role_id == @admin_role_id
    end)
  end

  def admin?(_), do: false
end
