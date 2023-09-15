defmodule Recognizer.Accounts.VerificationCode do
  @moduledoc """
  `Ecto.Schema` for a user's verification code.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Recognizer.Accounts.User

  @verification_code_len 32

  schema "verification_codes" do
    field :code

    belongs_to :user, User

    timestamps()
  end

  def changeset(code, attrs \\ %{}) do
    code
    |> cast(attrs, [:user_id, :code])
    |> validate_required([:user_id, :code])
    |> assoc_constraint(:user)
  end

  def generate_code() do
    @verification_code_len
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64()
    |> binary_part(0, @verification_code_len)
  end
end
