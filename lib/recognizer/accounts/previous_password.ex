defmodule Recognizer.Accounts.PreviousPassword do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  alias Recognizer.Accounts.User

  schema "previous_passwords" do
    field :hashed_password, :string

    belongs_to :user, User

    timestamps()
  end

  def changeset(previous_password, attrs \\ %{}) do
    previous_password
    |> cast(attrs, [:user_id, :hashed_password])
    |> validate_required([:user_id, :hashed_password])
  end
end
