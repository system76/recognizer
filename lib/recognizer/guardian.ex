defmodule Recognizer.Guardian do
  @moduledoc """
  All functions related to JWT reading and writing.
  """

  use Guardian, otp_app: :recognizer

  def subject_for_token(%Recognizer.Accounts.User{id: id}, _claims) do
    {:ok, "user:" <> to_string(id)}
  end

  def subject_for_token(_, _) do
    {:error, :unknown_resource}
  end

  def resource_from_claims("user" <> user_id) do
    {:ok, Accounts.get_user(user_id)}
  end

  def resource_from_claims(_) do
    {:error, :unknown_resource}
  end

  def encode_and_sign_access_token(access_token) do
    user = Keyword.get(access_token, :resource_owner)
    scopes =
      access_token
      |> Keyword.get(:scopes, [])
      |> String.split(" ")

    {:ok, token, _claims} = encode_and_sign(user, %{scopes: scopes}, [
      token_type: "access",
      ttl: {Keyword.get(access_token, :expires_in), :seconds}
    ])

    token
  end
end
