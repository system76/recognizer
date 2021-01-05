defmodule Recognizer.Accounts.RecoveryCode do
  @moduledoc """
  `Ecto.Schema` for a user's recovery codes.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Recognizer.Accounts.User

  @recovery_code_len 32

  schema "recovery_codes" do
    field :code

    belongs_to :user, User

    timestamps()
  end

  def changeset(recovery_code, attrs \\ %{}) do
    recovery_code
    |> cast(attrs, [:code, :user_id])
    |> validate_required([:code, :user_id])
    |> assoc_constraint(:user)
  end

  def generate_codes(count \\ 6) do
    for _x <- 0..(count - 1) do
      @recovery_code_len
      |> :crypto.strong_rand_bytes()
      |> Base.url_encode64()
      |> binary_part(0, @recovery_code_len)
    end
  end
end
