defmodule Recognizer.Accounts.Organization do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  alias __MODULE__, as: Organization
  alias Recognizer.Accounts.User

  schema "organizations" do
    field :name, :string

    field :password_reuse, :integer
    field :password_expiration, :integer
    field :two_factor_app_required, :boolean, default: false

    has_many :users, User

    timestamps()
  end

  def changeset(%Organization{} = org, attrs) do
    org
    |> cast(attrs, [:name, :password_expiration, :password_reuse, :two_factor_app_required])
    |> validate_required([:name])
  end
end
